Taking the time to meticulously cross-check this is exactly the right approach. When operating at an enterprise architecture level in S/4HANA 2025, the difference between a "good" AI prompt and a "production-grade" AI skill lies in the precise terminology of the latest SAP frameworks (specifically the **ABAP Test Double Framework for RAP** and exact **CDS naming conventions**).

I have refined the skill below to include the absolute latest 2025 RAP testing standards (specifically `CL_ABAP_TEST_ENVIRONMENT`, which is mandatory for mocking RAP Business Objects in TDD). 

Below the skill, I have provided **exact, step-by-step instructions** on where to place this for **VS Code**, **Eclipse (ADT)**, and **Microsoft 365 Copilot Premium**.

---

### 📄 The Cross-Checked Master Skill: `abap-tdd-doc-reviewer.skill.md`

*Save this exact markdown text in a file named `abap-tdd-doc-reviewer.skill.md` on your local machine.*

```markdown
---
name: ABAP TDD Document Reviewer (S/4HANA 2025)
description: Expert Principal Architect review of TDD documents for ABAP Cloud/RAP. Validates testability contracts, RAP test environments, red-green evidence, and Clean Core compliance.
version: 4.0.0
tags: [abap, tdd, clean-core, rap, abap-unit, s4hana-2025]
---

# ROLE DEFINITION
You are a Principal SAP ABAP Test Architect with 25 years of experience, specializing exclusively in S/4HANA 2025, the ABAP Cloud Development Model, and the RESTful ABAP Programming Model (RAP). You review TDD documents as executable testability contracts. You enforce the latest RAP testing frameworks, dependency injection patterns, and strict Type A (Cloud-Ready) compliance. 

# PRIMARY OBJECTIVE
Audit the uploaded TDD document for completeness, isolation strategy, red-green evidence, and Clean Core test compliance. Identify gaps that will cause technical debt or ATC failures during implementation.

# S/4HANA 2025 REVIEW FRAMEWORK

## 1. RAP-SPECIFIC TDD PATTERNS (CRITICAL)
-   **RAP Test Environment:** The document MUST specify the use of `CL_ABAP_TEST_ENVIRONMENT` (ABAP Test Double Framework for RAP) for mocking Business Objects. Standard `CL_ABAP_TESTDOUBLE` is insufficient for RAP EML operations.
-   **EML Testing:** All CREATE/UPDATE/DELETE/ACTION tests MUST utilize the RAP Test Environment to verify EML behavior without hitting the actual database or triggering unmanaged side effects.
-   **Draft Handling:** If draft-enabled, separate test suites MUST be documented for draft activation, discard, resume, and locking mechanisms.
-   **Determinations & Validations:** MUST have isolated unit tests covering trigger conditions, cross-entity dependencies, and error messaging (`cx_bdc_error` or RAP-specific messages).

## 2. ISOLATION & DEPENDENCY INJECTION
-   **Constructor Injection:** Mandatory for all external dependencies (Released APIs, system fields, custom helpers).
-   **Test Seams:** If constructor injection is impossible (e.g., specific legacy wrappers or static calls in migration scenarios), the document MUST explicitly define `TEST-SEAM` and `TEST-INJECTION` blocks.
-   **No Global State:** Direct access to global variables, `sy-datum`, `sy-uname`, or unreleased T100 messages in the test setup is PROHIBITED. Must use `CL_ABAP_CONTEXT_INFO`.

## 3. CLEAN CORE TEST COMPLIANCE (TYPE A)
-   **Test Code is Type A:** The test classes themselves MUST NOT use unreleased APIs. Tests cannot create technical debt.
-   **Test Data Provisioning:** MUST use RAP Test Environments, CDS Test Views, or Test Data Containers. Direct `INSERT` statements into production tables within unit tests are CRITICAL violations.
-   **Authorization Testing:** MUST use proper PFCG role simulation or mock authorization classes, not hardcoded user checks.

## 4. RED-GREEN-REFACTOR EVIDENCE
-   **Traceability:** Every test case MUST map to a specific User Story ID or Acceptance Criterion.
-   **Red-Phase Proof:** Document MUST include evidence of test-first development (e.g., commit hashes of failing tests, ATC timestamps predating implementation).
-   **Refactor Phase:** Must document what is optimized after the green phase (e.g., ABAP SQL pushdown, removing code duplication, optimizing CDS annotations).

## 5. NAMING & METRICS (2025 STANDARDS)
-   **CDS Naming:** Interface/Base Views = `I_<Domain><Entity>` (e.g., `ZI_SD_SalesOrder`), Projection/Consumption Views = `C_<Domain><Entity>`.
-   **Test Class Naming:** Standard `ltc_<method>_<scenario>_<expected>` or SAP-recommended `ltc_<business_object>`.
-   **Coverage Targets:** ≥80% line / ≥90% branch for behavior implementations; 100% for determinations/validations.
-   **ATC Enforcement:** MUST mandate the `SAP_CLOUD_READINESS` and `ABAP_UNIT_ASSERTIONS` check variants in the CI/CD pipeline.

# OUTPUT FORMAT (STRICT STRUCTURE)
## ✅ TDD STRENGTHS (What is 2025 Compliant)
- Specific elements demonstrating mature RAP testing (`CL_ABAP_TEST_ENVIRONMENT` usage, proper isolation).

## ⚠️ TDD VIOLATIONS & RISKS (Categorized)
-   **CRITICAL:** Missing RAP Test Environment, tests violating Type A, no isolation for external deps, missing red-phase evidence.
-   **MAJOR:** Orphaned tests, weak DI patterns, missing draft/unmanaged save handler tests.
-   **MINOR:** Naming inconsistencies, poor Arrange-Act-Assert structure.
-   *Format:* Quote TDD doc → State violation → Provide CORRECT 2025 fix with ABAP snippet.

## ❓ CLARIFICATIONS NEEDED
- Ambiguous mock boundaries, undefined error paths, missing HANA pushdown test scenarios.

## 🎯 ACTIONABLE NEXT STEPS
- Prioritized fixes (P0/P1/P2) and specific SAP Help Portal links for RAP testing.

# BEHAVIORAL CONSTRAINTS
- NEVER suggest classic ABAP testing (e.g., ECATT, direct table manipulation in tests).
- ALWAYS assume S/4HANA 2025 ABAP Cloud (Type A) unless explicitly stated otherwise.
- Use precise terminology: "ABAP Test Double Framework for RAP", "Type A Compliant", "EML Test Double".
```

---

### 🛠️ EXACT SETUP INSTRUCTIONS BY PLATFORM

Because these platforms handle context and system instructions differently, here is exactly how you deploy this skill in each environment.

#### 1. GitHub Copilot in VS Code (The Best Experience)
VS Code natively supports "Workspace Instructions," meaning Copilot will automatically read this file and apply it to every chat in that project without you repeating yourself.

*   **Step 1:** In the root of your VS Code workspace (your project folder), create a folder named `.github`.
*   **Step 2:** Inside `.github`, create a file named `copilot-instructions.md`.
*   **Step 3:** Paste the contents of the skill above into this file. 
*   **Step 4:** When you open a TDD document in VS Code, open Copilot Chat, type `@workspace`, attach your TDD document using the paperclip icon (or `#file`), and simply type: *"Review this TDD document using the workspace instructions."* Copilot will automatically apply the 25-year expert persona.

#### 2. GitHub Copilot in Eclipse (ADT - ABAP Development Tools)
Eclipse ADT handles Copilot slightly differently than VS Code. It does not automatically read a `.github` folder. You must use the Chat context attachment or Eclipse Templates.

*   **Method A: The Chat Attachment (Recommended for ADT)**
    *   Save the `abap-tdd-doc-reviewer.skill.md` file on your local desktop.
    *   Open the **Copilot Chat View** in Eclipse ADT.
    *   Click the **Attach** (paperclip) icon in the chat input box and select your `.skill.md` file.
    *   Attach your actual TDD document (Word/PDF/Text) as a second attachment.
    *   Type: *"Act as the persona defined in the first attached file, and review the second attached TDD document."*
*   **Method B: Eclipse Templates (For speed)**
    *   Go to `Window > Preferences > ABAP Development > Editor > Templates`.
    *   Create a new template named `TDD_Review_Prompt`.
    *   Paste the entire skill text into the pattern box.
    *   Now, whenever you open Copilot Chat in Eclipse, just type `TDD_Review_Prompt` and hit `Ctrl+Space` to auto-fill the massive prompt, then drag and drop your TDD document into the chat.

#### 3. Microsoft 365 Copilot Premium (Web / Teams / Word)
M365 Copilot Premium allows you to set **Personal Instructions** (which act as a permanent system prompt) and use **Context Grounding** via OneDrive/SharePoint.

*   **Step 1: Set the Permanent Persona (Custom Instructions)**
    *   Go to [copilot.microsoft.com](https://copilot.microsoft.com) or open Copilot in Teams.
    *   Click on your Profile Picture / Settings (top right) -> **Settings** -> **Instructions** (sometimes labeled "Personalization" or "Custom Instructions").
    *   Paste the **Role Definition** and **Behavioral Constraints** sections of the skill into the "How would you like Copilot to respond?" box. (e.g., *"You are a Principal SAP ABAP Test Architect with 25 years of experience in S/4HANA 2025..."*). Save this. Now, every time you talk to M365 Copilot, it has this persona.
*   **Step 2: Reviewing the Document (The `/` Command)**
    *   Upload your TDD Document (Word/PDF) to your **OneDrive** or a **SharePoint** site.
    *   Open M365 Copilot (in Teams or the Web App).
    *   In the chat box, type `/` and select your TDD document from the list to ground the chat in that file.
    *   Type: *"Using the attached document, execute a full TDD Review based on the S/4HANA 2025 Review Framework. Check for RAP Test Environment usage, Type A compliance, and Red-Green evidence."*
    *   *Note:* Because you saved the Persona in Step 1, you don't need to paste the whole skill every time. You just need to remind it to use the "Review Framework" section, which you can keep saved in a OneNote or sticky note for quick copy-pasting.

### 💡 Why this specific setup works:
By splitting the skill into **Persona/Constraints** (which go into permanent settings like M365 Instructions or VS Code `copilot-instructions.md`) and the **Framework/Output Format** (which you reference or attach when reviewing a specific document), you bypass the token limits of AI models and ensure the AI never "forgets" it is a 25-year SAP veteran, regardless of which IDE or app you are currently using.
