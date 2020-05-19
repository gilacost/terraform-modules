resource "heroku_app" "default" {
  name        = var.name
  region      = var.region
  config_vars = var.config_vars_map
  buildpacks  = var.buildpack_list
}

# Create a Heroku pipeline
resource "heroku_pipeline" "test-app" {
  name = "test-${var.name}"

  owner {
    id   = var.owner_id
    type = "user"
  }
}

resource "heroku_pipeline_coupling" "production" {
  app      = heroku_app.default.name
  pipeline = heroku_pipeline.test-app.id
  stage    = "production"
}
