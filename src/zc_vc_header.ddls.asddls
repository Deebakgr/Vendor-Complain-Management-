@EndUserText.label: 'Projection View for Complaint Header'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_VC_HEADER 
  provider contract transactional_query
  as projection on ZI_VC_HEADER
{
  @Search.defaultSearchElement: true
  key complaint_id,
  
  @Search.defaultSearchElement: true
  @ObjectModel.text.element: ['vendor_name'] 
  vendor_id,
  vendor_name,
  
  complaint_date,
  description,
  
  @Search.defaultSearchElement: true
  status,
  StatusCriticality,
  
  @Search.defaultSearchElement: true
//  @Consumption.valueHelpDefinition:[{ entity: { name: 'ZC_VC_HEADER', element: 'priority' } }]
  priority,
  PriorityCriticality,
   PrioritySortCode,
  
  assigned_to,
  resolved_date,
  resolution_note,
  
  created_by,
  created_at,
  changed_by,
  changed_at,

  /* Associations */
  _Item : redirected to composition child ZC_VC_ITEM
}
