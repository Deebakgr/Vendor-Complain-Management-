@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Complaint Item'
define view entity ZI_VC_ITEM 
  as select from zvcm_comp_item
  association to parent ZI_VC_HEADER as _Header on $projection.complaint_id = _Header.complaint_id
{
 
  key complaint_id,
  key item_id,
  
  material_id,
  material_desc,
  
  @Semantics.quantity.unitOfMeasure: 'unit'
  quantity,
  unit,
  
  defect_type,
  defect_desc,
  
  @Semantics.user.createdBy: true
  created_by,
  @Semantics.systemDateTime.createdAt: true
  created_at,

  /* Associations */
  _Header // Make association public
}
