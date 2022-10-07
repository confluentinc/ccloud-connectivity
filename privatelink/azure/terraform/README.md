# privatelink/azure/terraform

Configure Azure Terraform Connectivity

Configure Confluent Cloud API Key and Secret

    export TF_VAR_CONFLUENT_CLOUD_API_KEY=<APIKEY>
    export TF_VAR_CONFLUENT_CLOUD_API_SECRET=<SECRET>
    export CONFLUENT_CLOUD_API_KEY=${TF_VAR_CONFLUENT_CLOUD_API_KEY}
    export CONFLUENT_CLOUD_API_SECRET=${TF_VAR_CONFLUENT_CLOUD_API_SECRET}

Use the supplied `terraform.tfvars` file to supply required parameters to
    
    # Resource tags
    owner_email    = "youremail@company.com"
    purpose        = "WhyAreYouCreatingThisInfrastructure"

    # Subscription ID
    subscription   = "your-azure-subscription"
    # Azure Region
    region         = "azure-region"
    # Azure Resource Group
    resource_group = "AzureResourceGroup"
    #Azure VNET Name
    vnet_name      = "AzureVNET"

    # Confluent Environment to use
    env_name       = "EnvironmentDisplayName"
    # Confluent Dedicated Cluster to create
    cluster_name   = "ClusterDisplayName"
    # CKU count of the dedicated cluster
    cluster_cku    = CKUCount
    # Confluent Private Link Network Name
    network_name   = "NetworkDisplayName"

    # KSQL Cluster Name
    ksql_cluster   = "KSQLClusterName"
    # App ID for KSQL cluster. will be provisioning with ClusterAdmin role
    ksql_app_id    = "AppID"

Lifecycle parameter is commented out now. To prevent accidentally destroying resource, uncomment the block on the resource
    
    # Uncomment if you don't want cluster to be destroyed
    # lifecycle {
    #  prevent_destroy = true
    # }

After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply -target azurerm_private_dns_zone.hz
    terraform apply 

To Destroy, use `terraform destroy`

    terraform destroy -target azurerm_private_endpoint.endpoint
    terraform destroy -target azurerm_private_dns_zone.hz
    terraform destroy -target confluent_network.azure-private-link
    terraform destroy 