# azfirewall_terraform
Azure Firewall Terraform Module
# Azure Firewall Configuration

This Terraform configuration defines resources for deploying an Azure Firewall in an Azure environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Variables](#variables)
- [License](#license)

## Prerequisites

Before using this Terraform configuration, ensure you have:

- An Azure subscription.
- Terraform installed on your local machine.

## Usage

1. Clone this repository:

    ```bash
    git clone <repository-url>
    ```

2. Navigate to the directory containing the Terraform files:

    ```bash
    cd <repository-directory>
    ```

3. Initialize Terraform:

    ```bash
    terraform init
    ```

4. Review and adjust the variables in `variables.tf` file as needed.

5. Apply the Terraform configuration:

    ```bash
    terraform apply
    ```

6. Confirm the changes and enter "yes" when prompted to deploy the resources.

## Variables

- `create_resource_group`: (boolean) Whether to create a new resource group or use an existing one.
- `resource_group_name`: (string) Name of the resource group to use or create.
- `location`: (string) Azure region where the resources will be deployed.
- `virtual_network_name`: (string) Name of the virtual network where the firewall will be deployed.
- `public_ip_names`: (list(string)) List of public IP names to associate with the firewall.
- ... (Other variables can be found in `variables.tf`)

For a detailed explanation of each variable, refer to the `variables.tf` file.

## License

This project is licensed under the MIT License
