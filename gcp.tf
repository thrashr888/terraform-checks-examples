data "google_compute_network" "default" {
  name                    = "default"
}
 
resource "google_compute_instance" "vm_instance" {
  name         = "my-instance"
  machine_type = "f1-micro"
 
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
 
  network_interface {
    network = data.google_compute_network.default.name
    access_config {
    }
  }
}
 
check "check_vm_status" {
 
  # Note: in this example we reference the resource directly instead of using a data source (or a data source that is scoped to this check block)
 
  assert {
    condition = google_compute_instance.vm_instance.current_status == "RUNNING"
    error_message = format("Provisioned VMs should be in a RUNNING status, instead the VM `%s` has status: %s",
      google_compute_instance.vm_instance.name,
      google_compute_instance.vm_instance.current_status
    )
  }
}

# ----------------------------------------

locals {
  month_in_hour_duration = "${24 * 30}h"
  month_and_2min_in_second_duration = "${(60 * 60 * 24 * 30) + (60 * 2)}s"
}
 
resource "tls_private_key" "example" {
  algorithm   = "RSA"
}
 
resource "tls_cert_request" "example" {
  private_key_pem = tls_private_key.example.private_key_pem
 
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}
 
resource "google_privateca_ca_pool" "default" {
  name     = "my-ca-pool"
  location = "us-central1"
  tier     = "ENTERPRISE"
  publishing_options {
    publish_ca_cert = true
    publish_crl = true
  }
  labels = {
    terraform = true
  }
  issuance_policy {
    baseline_values {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          digital_signature = true
          key_encipherment = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }
}
 
resource "google_privateca_certificate_authority" "test-ca" {
  deletion_protection      = false
  certificate_authority_id = "my-authority"
  location                 = google_privateca_ca_pool.default.location
  pool                     = google_privateca_ca_pool.default.name
  config {
    subject_config {
      subject {
        country_code = "us"
        organization = "google"
        organizational_unit = "enterprise"
        locality = "mountain view"
        province = "california"
        street_address = "1600 amphitheatre parkway"
        postal_code = "94109"
        common_name = "my-certificate-authority"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }
  type = "SELF_SIGNED"
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256"
  }
}
 
resource "google_privateca_certificate" "default" {
  name                  = "my-certificate"
  pool                  = google_privateca_ca_pool.default.name
  certificate_authority = google_privateca_certificate_authority.test-ca.certificate_authority_id
  location              = google_privateca_ca_pool.default.location
  lifetime              = local.month_and_2min_in_second_duration # lifetime is 2mins over the threshold in the check block below
  pem_csr               = tls_cert_request.example.cert_request_pem
}
 
check "check_certificate_state" {
 
  assert {
    condition = timecmp(plantimestamp(), timeadd(
google_privateca_certificate.default.certificate_description[0].subject_description[0].not_after_time,
      "-${local.month_in_hour_duration}")) < 0
    error_message = format("Provisioned certificates should be valid for at least 30 days, but `%s`is due to expire on `%s`.",
    google_privateca_certificate.default.name,
    
google_privateca_certificate.default.certificate_description[0].subject_description[0].not_after_time
    )
  }
}

# -------------------------------------------

resource "google_storage_bucket" "bucket" {
  name     = "my-bucket"
  location = "US"
  uniform_bucket_level_access = true
}
 
resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./function-source.zip"
}
 
resource "google_cloudfunctions2_function" "my-function" {
  name = "my-function"
  location = "us-central1"
  description = "a new function"
 
  build_config {
    runtime = "nodejs12"
    entry_point = "helloHttp"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }
 
  service_config {
    max_instance_count  = 1
    available_memory    = "1536Mi"
    timeout_seconds     = 30
  }
}
 
check "check_cf_state" {
  data "google_cloudfunctions2_function" "my-function" {
    name = google_cloudfunctions2_function.my-function.name
    location = google_cloudfunctions2_function.my-function.location
  }
 
  assert {
    condition = data.google_cloudfunctions2_function.my-function.state == "ACTIVE"
    error_message = format("Provisioned Cloud Functions should be in an ACTIVE state, instead the function `%s` has state: %s",
      data.google_cloudfunctions2_function.my-function.name,
      data.google_cloudfunctions2_function.my-function.state
    )
  }
}
