# EduChain 📚🔗

**Decentralized Education Credential Verification System**
*Supporting UN SDG Goal 4: Quality Education*

EduChain is a Clarity smart contract designed for transparent, tamper-proof issuance and verification of educational credentials on a blockchain. It enables institutions to securely issue verifiable academic records and empowers employers, students, and other stakeholders to validate them with ease.

---

## 🌍 Purpose

This project aligns with **UN Sustainable Development Goal 4** – *Ensure inclusive and equitable quality education and promote lifelong learning opportunities for all* – by reducing credential fraud and improving access to verifiable educational achievements.

---

## ✨ Key Features

* **Credential Verification**: Public, immutable validation of educational credentials.
* **Decentralized Trust**: Institutions must be registered and accredited before issuing records.
* **Tamper-Proof Records**: Each credential includes a verifiable IPFS hash for the associated certificate.
* **Ownership and Control**: Only authorized issuers can create or revoke credentials.
* **Student-Focused**: Students can access their own list of credentials via wallet address.

---

## 🏗️ Data Structures

### Institutions

Stores metadata for registered academic institutions.

```clojure
institution-id -> {
  name,
  accreditation-body,
  authorized-issuer,
  is-active,
  registration-block
}
```

### Credentials

Represents issued educational records.

```clojure
credential-id -> {
  student-address,
  institution-id,
  degree-type,
  field-of-study,
  graduation-date,
  gpa,
  ipfs-hash,
  issue-block,
  is-verified
}
```

### Student Credentials

Maps a student address to a list of credential IDs.

```clojure
student -> {
  credential-ids (max 20)
}
```

---

## 🔐 Access Control

* `CONTRACT_OWNER`: Only the contract owner can register institutions and update their authorized issuers.
* `authorized-issuer`: Only the assigned issuer for an institution can issue or revoke credentials.

---

## ⚙️ Core Functions

### ✅ Public Functions

| Function                    | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `register-institution`      | Adds a new institution (owner only).              |
| `issue-credential`          | Issues a new credential (authorized issuer only). |
| `revoke-credential`         | Marks a credential as unverified (issuer only).   |
| `deactivate-institution`    | Deactivates an institution (owner only).          |
| `update-institution-issuer` | Changes the authorized issuer (owner only).       |

### 🔍 Read-Only Functions

| Function                  | Description                                                    |
| ------------------------- | -------------------------------------------------------------- |
| `get-institution`         | Retrieves institution metadata.                                |
| `get-credential`          | Retrieves credential details.                                  |
| `get-student-credentials` | Lists credentials by student wallet address.                   |
| `verify-credential`       | Returns basic verified metadata for a credential.              |
| `get-contract-stats`      | Provides statistics: total institutions/credentials, next IDs. |

---

## 📦 Example Credential

```json
{
  "student-address": "SP3...",
  "institution-id": 1,
  "degree-type": "BSc",
  "field-of-study": "Computer Science",
  "graduation-date": 20240501,
  "gpa": 375,
  "ipfs-hash": "QmT5NvUtoM5nX3e...",
  "is-verified": true
}
```

---

## 🚫 Errors

| Error Code | Description                                            |
| ---------- | ------------------------------------------------------ |
| `u100`     | Unauthorized access.                                   |
| `u101`     | Institution not found.                                 |
| `u102`     | Credential not found.                                  |
| `u103`     | Institution already exists.                            |
| `u104`     | Credential already exists.                             |
| `u105`     | Invalid input (e.g., empty strings, GPA out of range). |

---

## 📄 IPFS Integration

Each credential includes an `ipfs-hash` that links to a decentralized copy of the academic certificate, allowing for independent verification of documents.

---

## 🔧 Development & Deployment

This contract is written in **Clarity**, a safe and decidable smart contract language for the [Stacks Blockchain](https://www.stacks.co/).

To deploy and test:

1. Install Clarity tools via [Clarinet](https://docs.stacks.co/docs/clarity/clarinet-cli/overview/).
2. Clone the repo and test:

   ```bash
   clarinet test
   ```
3. Deploy on Stacks Testnet or Mainnet using Clarinet or a UI interface like Hiro.

---

## 🤝 Contributing

Want to contribute? PRs and issues are welcome! Help us advance SDG Goal 4 by building open infrastructure for academic credentialing.

---

## 📘 License

This project is open-source and licensed under the [MIT License](LICENSE).
