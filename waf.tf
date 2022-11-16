# Adapted from: https://brk0018.medium.com/implement-cloud-armor-security-policy-s-using-terraform-1794792e2842 and
# https://cloud.google.com/armor/docs/rule-tuning

# Notable exclusions:
# OWASP method enforcement is not restricted since we are fronting RESTful apis through BFFs and those may presumably use
# other HTTP methods than the default GET/POST/OPTIONS/HEAD - which is supposedly what this rule covers.

resource google_compute_security_policy lb_security_policy {
  project = var.project_id
  name = "lb-security-policy"
  
  # OWASP preconfigured sensitivity level 1
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable', ['owasp-crs-v030001-id941150-xss', 'owasp-crs-v030001-id941320-xss', 'owasp-crs-v030001-id941330-xss', 'owasp-crs-v030001-id941340-xss'])"
      }
    }
    description = "xss sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1100"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-canary')"
      }
    }
    description = "local file inclusion sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1200"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable', ['owasp-crs-v030001-id942110-sqli', 'owasp-crs-v030001-id942120-sqli', 'owasp-crs-v030001-id942150-sqli',  'owasp-crs-v030001-id942180-sqli', 'owasp-crs-v030001-id942200-sqli', 'owasp-crs-v030001-id942210-sqli', 'owasp-crs-v030001-id942260-sqli', 'owasp-crs-v030001-id942300-sqli', 'owasp-crs-v030001-id942310-sqli', 'owasp-crs-v030001-id942330-sqli', 'owasp-crs-v030001-id942340-sqli', 'owasp-crs-v030001-id942380-sqli', 'owasp-crs-v030001-id942390-sqli', 'owasp-crs-v030001-id942400-sqli', 'owasp-crs-v030001-id942410-sqli', 'owasp-crs-v030001-id942430-sqli', 'owasp-crs-v030001-id942440-sqli', 'owasp-crs-v030001-id942450-sqli', 'owasp-crs-v030001-id942251-sqli', 'owasp-crs-v030001-id942420-sqli', 'owasp-crs-v030001-id942431-sqli', 'owasp-crs-v030001-id942460-sqli', 'owasp-crs-v030001-id942421-sqli', 'owasp-crs-v030001-id942432-sqli'])"
      }
    }
    description = "sqli sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1300"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rfi-canary', ['owasp-crs-v030001-id931130-rfi'])"
      }
    }
    description = "remote file inclusion sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1400"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('scannerdetection-stable', ['owasp-crs-v030001-id913101-scannerdetection', 'owasp-crs-v030001-id913102-scannerdetection'])"
      }
    }
    description = "scanner detection sensitivity level 1"
  }
          
  rule {
    action   = "deny(403)"
    priority = "1500"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('protocolattack-stable', ['owasp-crs-v030001-id921151-protocolattack', 'owasp-crs-v030001-id921170-protocolattack'])"
      }
    }
    description = "protocol attack sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1600"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('php-stable', ['owasp-crs-v030001-id933151-php', 'owasp-crs-v030001-id933131-php', 'owasp-crs-v030001-id933161-php', 'owasp-crs-v030001-id933111-php'])"
      }
    }
    description = "php injection sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1700"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sessionfixation-canary')"
      }
    }
    description = "session fixation sensitivity level 1"
  }

  rule {
    action   = "deny(403)"
    priority = "1800"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('cve-canary', ['owasp-crs-v030001-id244228-cve', 'owasp-crs-v030001-id344228-cve'])"
      }
    }
    description = "log4j sensitivity level 1"
  }

  # Rules passed so allow if we're from allowed regions
  rule {
    action   = "deny(403)"
    priority = "10000"
    match {
      expr {
        expression = "origin.region_code == 'DE' || origin.region_code == 'RU' || origin.region_code == 'CN' "
      }
    }
    description = "Region deny list"
  }

  # deny everything else
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}