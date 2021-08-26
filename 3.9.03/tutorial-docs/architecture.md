### Supported Regions

DRAGEN on Azure is available in regions where FPGA-enabled [Standard NP Family VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/np-series) are available.  At the time of this writing, supported regions currently include:

* West US 2
* East US
* Southeast Asia (Singapore)
* West Europe (Amsterdam)

For the most current information on available regions, see the NP-series row of the chart [here](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=virtual-machines).

### Architecture Diagram

![architecture-diagram](./images/dragen-on-azure.png)

### Resource List

List of Azure resources that are deployed by this quickstart if default settings and parameters are used:

* [Azure Blob Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview) for input and output data
    * Note: A new storage account is created by default, although users have the option to specify an existing storage account - see section on additional deployment configurations
    * [Blob Storage Container](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction#containers)
* [Azure Batch Account](https://docs.microsoft.com/en-us/azure/batch/batch-technical-overview) for managing and scheduling DRAGEN jobs.
    * Provisioned in [User Subscription Mode](#user-subscription-node-pools).
    * [Node pool](https://docs.microsoft.com/en-us/azure/batch/nodes-and-pools) backed by one [NP-series VM](https://docs.microsoft.com/en-us/azure/virtual-machines/np-series) (fixed scale).
* [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general/basic-concepts) for batch service auth to User Subscription node pool VMs
    * Note: Batch service handles auth automatically, so users do not need to take any further action after the Key Vault is created.

### Note on Batch Node Pool Allocation

Batch offers two options for allocation of node pools: Batch managed and user subscription modes. A single Batch Account can only support one node pool type at a time, meaning you cannot have batch managed and user subscription mode node pools under the same batch account.

#### Batch Managed Node Pools

When Batch Managed allocation mode is selected, users must request NP VM quota for each specific Batch instance they create.  Nodes are allocated as needed from Batch-managed subscriptions.  This scenario works best when users intend to persist and use one or very few Batch instances for their DRAGEN jobs.  It is less ideal in situations where the creation/deletion of Batch accounts is automated or occurs frequently, as with CI/CD.

#### User Subscription Node Pools

When the User Subscription allocation mode is selected, users request an overall quota for NP VMs for a region within their subscription.  With this model, the VMs needed for the Batch account are created directly in the user's subscription.  This setup is useful for CI/CD and other cases where users are running DRAGEN across many Batch accounts within a subscription and/or the Batch accounts are short-lived.

#### Cost Differences in Node Pool Allocation Modes

There may be cost differences between the two different node pool allocation methods.  Consider your usage scenarios and consult Azure documentation and pricing calculators to determine which approach will be most optimal for your needs.

### Azure Costs

Users are responsible for costs of any services deployed through this quickstart or its customization options.

Prices are subject to change - more information can be found on the pricing pages for Azure resources deployed through this tutorial:

* [Azure Blob Storage](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/)
* [Azure Batch](https://azure.microsoft.com/en-us/pricing/details/batch/windows-virtual-machines/)
    * _Note: There is currently no charge for Batch itself, only the compute resources it uses; see VM pricing below_
* [Azure NP-series VMs](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/#np-series) (a NP10s is used in this reference deployment)
* [Azure Key Vault](https://azure.microsoft.com/en-us/pricing/details/key-vault/#pricing)

Users are also responsible for costs of any licenses needed to run DRAGEN (not included in this quickstart - must be obtained separately).

#### Estimate your Costs

For help in estimating your costs to run DRAGEN on Azure, see the pricing calculator located [here](https://azure.microsoft.com/en-us/pricing/calculator/).
