@EndUserText.label: 'Projection View for Complaint Item'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_VC_ITEM 
  as projection on ZI_VC_ITEM    
{
  key complaint_id,
  key item_id,
  
  material_id,
  material_desc,
  
  quantity,
  unit,
  
  defect_type,
  defect_desc,
  
  created_by,
  created_at,

  /* Associations */
  _Header : redirected to parent ZC_VC_HEADER
}
