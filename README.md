# *Vendor Complaint Management System*
### *SAP RAP (Unmanaged Scenario) with Fiori UI*

---

## *Overview*
The *Vendor Complaint Management System* is developed using the *ABAP RESTful Application Programming Model (RAP)* in an *Unmanaged scenario*.

This application helps organizations to *create, track, and manage vendor complaints* efficiently using a modern *SAP Fiori UI OData 4* interface.

The unmanaged RAP approach allows full control over *custom business logic*, including validations, status handling, and complaint processing.

---

## *Key Features*

* Create and manage vendor complaints  
* View complaint details with status tracking  
* Update complaint status (Open, In Progress, Resolved, Closed)  
* Custom validations and error handling  
* CDS-based data modeling  
* Fiori UI5 responsive interface  
* Backend logic using unmanaged RAP  

---

## *Architecture*

### *Database Layer*
* Custom table: ZVENDOR_COMPLAINT  
* Fields:
  * Complaint ID  
  * Vendor ID  
  * Description  
  * Status  
  * Created Date  
  * Priority  

### *CDS Layer*
* Interface View: ZI_VENDOR_COMPLAINT  
* Projection View: ZC_VENDOR_COMPLAINT  
* UI annotations included  

### *Behavior Layer (Unmanaged)*
* Behavior Definition (BDEF)  
* Behavior Implementation (BIMP)  
* Manual implementation of:
  * Create  
  * Update  
  * Delete  
  * Validations  
  * Actions  

### *Service Layer*
* Service Definition  
* Service Binding (OData V4)  

### *UI Layer*
* SAP Fiori UI4 (Version 4)  
* Connected using OData V4  

---

## *Technologies Used*

* ABAP RAP (Unmanaged Scenario)  
* CDS Views  
* OData V4  
* SAP Fiori UI (v4)  
* Eclipse ADT / SAP BAS  

---

## *Workflow*

1. User creates complaint via Fiori UI  
2. Request is sent to RAP service  
3. Business logic is handled in unmanaged implementation  
4. Data is stored in database  
5. Status updates are processed  
6. User tracks complaint lifecycle  

---
