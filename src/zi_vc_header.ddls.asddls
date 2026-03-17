@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Complaint Header'
define root view entity ZI_VC_HEADER 
  as select from zvc_header
  composition [0..*] of ZI_VC_ITEM  as _Item
{
 
  key complaint_id,
  
  vendor_id,
  vendor_name,
  complaint_date,
  description,
  
  status,
  // 1 = Red (Negative), 2 = Orange (Critical), 3 = Green (Positive), 5 = Blue (Info)
  case status
    when 'Resolved'     then 3 
    when 'Review' then 2 
    when 'Open'         then 5 
    when 'Closed'       then 5
    else 0 
  end as StatusCriticality,
  
//  @Consumption.valueHelpDefinition:[{ entity: { name: 'ZI_VC_HEADER', element: 'priority' } }]
  priority,
  case priority
    when 'Critical'     then 1 
    when 'High'         then 2 
    when 'Medium'       then 5 
    when 'Low'          then 3
    else 0 
  end as PriorityCriticality,
  
  case priority
    when 'Critical'     then 1 
    when 'High'         then 2 
    when 'Medium'       then 3 
    when 'Low'          then 4
    else 5 
  end as PrioritySortCode,
  
  assigned_to,
  resolved_date,
  resolution_note,
  
  @Semantics.user.createdBy: true
  created_by,
  @Semantics.systemDateTime.createdAt: true
  created_at,
  @Semantics.user.lastChangedBy: true
  changed_by,
  @Semantics.systemDateTime.lastChangedAt: true
  changed_at,

  _Item // Make association public
}
