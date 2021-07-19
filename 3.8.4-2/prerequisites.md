* **A DRAGEN License** - Contact Illumina.
* **Access to DRAGEN Image via Azure Marketplace** - If you would like to gain access, please contact Illumina at techsupport@illumina.com.

### Technical Requirements

* **Azure Subscription.** An Azure Cloud Subscription.
* **Quota for NP-Series Virtual Machines.** You will need to request a quota
  for vCPU cores for the NP-series of virtual machines on Azure.
* **Azure CLI.** You'll need to [install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) the Azure CLI.
* **Genomic Data.** This quick start will create (if it does not already exist) an
  Azure Blob Storage Account. You will need to upload your genomics data to this
  storage account to utilize DRAGEN.

### Quota Requirements

DRAGEN runs on a specific Virtual Machine SKU family in Azure, because it requires
**field-programmable gate array** (FPGA) hardware.  Due to this requirement, you
will need to request access to this Virtual Machine SKU family, as described below.

#### NP-Series VMs

DRAGEN runs on FPGA-enabled VMs, which are now generally available as the [NP-series](https://docs.microsoft.com/en-us/azure/virtual-machines/np-series) on Azure.

> Currently, the vCPU requirements for NP-series SKUs are in increments of 10. When requesting an updated quota, we recommend requesting vCPUs in batches of 10. You will need a minimum increase of 10 vCPU Quota for NP-series machines for this tutorial.

For steps to increase or verify your NP-series vCPU quota on Azure, follow [this deployment step](#login-to-your-azure-portal-account).

#### Batch Accounts

This quickstart will utilize [Azure Batch](https://azure.microsoft.com/en-us/services/batch/) as the computing environment for DRAGEN, in [user subscription mode](https://docs.microsoft.com/en-us/azure/batch/scripts/batch-cli-sample-create-user-subscription-account).

It is also possible to run Azure Batch in **Batch service allocation mode**. In Batch service allocation mode, compute nodes are subject to a separate quota. For DRAGEN, in Batch service allocation mode, you will need to request additional quota for NP-series vCPUs for your discrete Azure Batch account. Current default quotas for Batch accounts can be found [here](https://docs.microsoft.com/en-us/azure/batch/batch-quota-limit#resource-quotas). You can increase your Azure Batch account quota by [following the steps here](https://docs.microsoft.com/en-us/azure/batch/batch-quota-limit#increase-a-quota).

#### Required Permissions (Authorization / Access Controls)

To provision this solution, the Active Directory principal (account, service principal, etc.) should require at least Azure subscription-wide [contributor access](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor).

If your organization is concerned about this level of access, a deployment pipeline (e.g., GitHub Actions) running as a managed service principal with ***contributor*** access can allow others to have a more restricted privilege level (e.g., Resource Group Contributor, Subscription Reader).

When utilizing a User Subscription Mode Batch Account, the Azure Batch Service must be added to the Azure Subscription as a Contributor. To add this level of access, you must be at least a Subscription Contributor. For more see [additional configuration for user subscription mode](https://docs.microsoft.com/en-us/azure/batch/batch-account-create-portal#additional-configuration-for-user-subscription-mode).
