# IaC Practices - Azure Bicep Demo

# English

This repository contains a basic Azure architecture deployment at Resource Group scope using Bicep.

### Files

- `IaC 101/main.bicep`
- `IaC 101/demo.parameters.json`
- `IaC 101/values.txt`

### What It Deploys

- 2 VNets (`vnet-a`, `vnet-b`)
- 1 `app` subnet in each VNet
- VNet peering (A -> B and B -> A)
- Linux and Windows VMs from `vmPlan`
- One NIC per VM

### Prerequisites

- Azure subscription
- Azure CLI (`az`)

```bash
az version
az bicep version
```

### Deploy

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
az group create --name rg-iac101-demo --location northeurope
az deployment group create \
  --resource-group rg-iac101-demo \
  --template-file "IaC 101/main.bicep" \
  --parameters "IaC 101/demo.parameters.json" \
  --parameters adminPassword="<STRONG_PASSWORD>"
```

### GitHub Actions (Choose one)

You can use either **Secrets** (fast setup) or **OIDC** (no client secret). Keep one and ignore the other.

#### Option A: Secrets (fast setup)

1. Create a Service Principal and copy the JSON output:
   ```bash
   az account show --query id --output tsv
   az ad sp create-for-rbac --name "IaC-Practices-Deployer" --role contributor --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> --sdk-auth
   ```

2. Add GitHub repository secrets:
   - Repo > Settings > Secrets and variables > Actions > Secrets
   - `AZURE_CREDENTIALS` (paste the JSON output)
   - `ADMIN_PASSWORD` (strong VM password)

Secrets summary:
- `AZURE_CREDENTIALS`: Service Principal JSON
- `ADMIN_PASSWORD`: VM admin password

Now every push to `main` will authenticate and deploy the Bicep template.

#### Option B: OIDC (no client secret)

1. Create an App Registration:
   - Azure Portal > Microsoft Entra ID > App registrations > New registration
   - Name: `IaC-Practices-Deployer`

2. Assign RBAC role to the app (least privilege):
   - Azure Portal > Resource groups > `rg-iac101-demo` > Access control (IAM)
   - Add role assignment: **Contributor**
   - Assign access to: **User, group, or service principal**
   - Select: `IaC-Practices-Deployer`

3. Add a Federated Credential (OIDC):
   - App registration > Federated credentials > Add credential
   - Scenario: **GitHub Actions** (or use manual values if the template is not available)
   - Organization: `<YOUR_GITHUB_USER_OR_ORG>`
   - Repository: `IaC-Practices`
   - Entity type: **Branch**
   - Branch: `main`

4. Add GitHub repository variables (not secrets):
   - Repo > Settings > Secrets and variables > Actions > Variables
   - `AZURE_CLIENT_ID` (from App registration)
   - `AZURE_TENANT_ID` (from Entra ID overview)
   - `AZURE_SUBSCRIPTION_ID` (from Subscription overview)

When you use OIDC, switch the workflow login step to use `azure/login@v2` with client-id/tenant-id/subscription-id and remove `AZURE_CREDENTIALS`.

### Push To GitHub

```bash
git add .
git commit -m "Update README"
git push -u origin main
```

### Security

- Do not keep `adminPassword` in files.
- Prefer Key Vault or CI/CD secrets.

------------------------------------------------------------------------------------------

# Turkce

Bu repo, Azure Resource Group seviyesinde Bicep ile temel bir mimari kurulumunu icerir.

### Dosyalar

- `IaC 101/main.bicep`
- `IaC 101/demo.parameters.json`
- `IaC 101/values.txt`

### Ne Deploy Edilir

- 2 adet VNet (`vnet-a`, `vnet-b`)
- Her VNet icinde 1 adet `app` subnet
- VNet peering (A -> B ve B -> A)
- `vmPlan` ile Linux ve Windows VM'ler
- Her VM icin bir NIC

### On Kosullar

- Azure aboneligi
- Azure CLI (`az`)

```bash
az version
az bicep version
```

### Deploy

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
az group create --name rg-iac101-demo --location northeurope
az deployment group create \
  --resource-group rg-iac101-demo \
  --template-file "IaC 101/main.bicep" \
  --parameters "IaC 101/demo.parameters.json" \
  --parameters adminPassword="<STRONG_PASSWORD>"
```

### GitHub Actions (Istedigini sec)

Iki yontem var: **Secret** (hizli kurulum) veya **OIDC** (client secret yok). Birini secip digerini kullanma.

#### Secenek A: Secret (hizli kurulum)

1. Service Principal olustur ve JSON ciktisini kopyala:
   ```bash
   az account show --query id --output tsv
   az ad sp create-for-rbac --name "IaC-Practices-Deployer" --role contributor --scopes /subscriptions/<ABONELIK_ID> --sdk-auth
   ```

2. GitHub repo secrets ekle:
   - Repo > Settings > Secrets and variables > Actions > Secrets
   - `AZURE_CREDENTIALS` (JSON ciktiyi yapistir)
   - `ADMIN_PASSWORD` (guclu VM parolasi)

Secrets ozeti:
- `AZURE_CREDENTIALS`: Service Principal JSON
- `ADMIN_PASSWORD`: VM admin parolasi

Artik `main` branch'e her push'ta deploy olur.

#### Secenek B: OIDC (client secret yok)

1. App Registration olustur:
   - Azure Portal > Microsoft Entra ID > App registrations > New registration
   - Name: `IaC-Practices-Deployer`

2. Uygulamaya RBAC rolu ver (minimum yetki):
   - Azure Portal > Resource groups > `rg-iac101-demo` > Access control (IAM)
   - Add role assignment: **Contributor**
   - Assign access to: **User, group, or service principal**
   - Sec: `IaC-Practices-Deployer`

3. Federated Credential (OIDC) ekle:
   - App registration > Federated credentials > Add credential
   - Scenario: **GitHub Actions** (yoksa manuel alanlari kullan)
   - Organization: `<GITHUB_KULLANICI_ORG>`
   - Repository: `IaC-Practices`
   - Entity type: **Branch**
   - Branch: `main`

4. GitHub repo variables ekle (secret degil):
   - Repo > Settings > Secrets and variables > Actions > Variables
   - `AZURE_CLIENT_ID` (App registration icinden)
   - `AZURE_TENANT_ID` (Entra ID overview)
   - `AZURE_SUBSCRIPTION_ID` (Subscription overview)

OIDC kullanacaksan workflow'da `azure/login@v2` icin client-id/tenant-id/subscription-id kullanip `AZURE_CREDENTIALS` satirini silmelisin.

### GitHub Push

```bash
git add .
git commit -m "README guncelle"
git push -u origin main
```

### Guvenlik

- `adminPassword` degerini dosyada tutmayin.
- Key Vault veya CI/CD secret kullanin.
