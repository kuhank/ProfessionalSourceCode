
Project RCM_Integrated {
  database_type: "SQL Server"
  note: 'Unified schema for Denials, Prior Auth (EPA), Charge Entry + standard RCM tables (clearinghouse, enrollments, fee schedules, refunds, adjustments, transactions, etc.)'
}

/////////////////////////////
// Core Master / Dimensions
/////////////////////////////

Table practice {
  practice_id int [pk, increment]
  customer_id int // optional multi-tenant key
  name nvarchar(200)
  type nvarchar(50)
  group_npi nvarchar(20)
  tax_id nvarchar(20)
  address1 nvarchar(200)
  address2 nvarchar(200)
  city nvarchar(80)
  state nvarchar(2)
  zip nvarchar(15)
  phone nvarchar(25)
  fax nvarchar(25)
  is_active bit
  created_at datetime
  updated_at datetime
}

Table facility {
  facility_id int [pk, increment]
  practice_id int [not null, ref: > practice.practice_id]
  name nvarchar(200)
  npi nvarchar(20)
  tax_id nvarchar(20)
  address1 nvarchar(200)
  address2 nvarchar(200)
  city nvarchar(80)
  state nvarchar(2)
  zip nvarchar(15)
  phone nvarchar(25)
  fax nvarchar(25)
  place_of_service_code nvarchar(5)
  is_active bit
  created_at datetime
  updated_at datetime
}

Table specialty {
  specialty_id int [pk, increment]
  name nvarchar(120)
  legend nvarchar(120)
  is_active bit
}

Table provider {
  provider_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  npi nvarchar(20)
  taxonomy_code nvarchar(20)
  first_name nvarchar(80)
  middle_name nvarchar(80)
  last_name nvarchar(80)
  degree nvarchar(20)
  physician_type nvarchar(50)
  email nvarchar(150)
  phone nvarchar(25)
  is_active bit
  created_at datetime
  updated_at datetime
}

Table provider_specialty {
  provider_id int [ref: - provider.provider_id]
  specialty_id int [ref: - specialty.specialty_id]
  practice_id int [ref: > practice.practice_id]
  is_active bit
  Primary Key (provider_id, specialty_id, practice_id)
}

Table patient {
  patient_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  account_no nvarchar(50)
  mrn nvarchar(50)
  first_name nvarchar(80)
  middle_name nvarchar(80)
  last_name nvarchar(80)
  dob date
  gender nvarchar(25)
  phone nvarchar(25)
  email nvarchar(120)
  address1 nvarchar(200)
  address2 nvarchar(200)
  city nvarchar(80)
  state nvarchar(2)
  zip nvarchar(15)
  is_active bit
  created_at datetime
  updated_at datetime
}

Table payer {
  payer_id int [pk, increment]
  name nvarchar(200)
  payer_code nvarchar(50)
  clearinghouse_id nvarchar(50)
  phone nvarchar(25)
  address1 nvarchar(200)
  city nvarchar(80)
  state nvarchar(2)
  zip nvarchar(15)
  is_active bit
}

Table payer_plan {
  payer_plan_id int [pk, increment]
  payer_id int [ref: > payer.payer_id]
  plan_name nvarchar(200)
  plan_code nvarchar(50)
  is_active bit
}

Table insurance_policy {
  insurance_policy_id int [pk, increment]
  patient_id int [ref: > patient.patient_id]
  payer_plan_id int [ref: > payer_plan.payer_plan_id]
  policy_number nvarchar(50)
  group_number nvarchar(50)
  effective_from date
  effective_to date
  ordinal int // 1=primary, 2=secondary...
  relationship_to_insured nvarchar(50)
  subscriber_first_name nvarchar(80)
  subscriber_last_name nvarchar(80)
  subscriber_dob date
  is_active bit
  created_at datetime
  updated_at datetime
}

Table cpt {
  cpt_id int [pk, increment]
  code nvarchar(10) [unique]
  description nvarchar(1000)
  is_active bit
  effective_from date
  effective_to date
}

Table icd10 {
  icd10_id int [pk, increment]
  code nvarchar(10) [unique]
  long_description nvarchar(1000)
  short_description nvarchar(300)
  is_active bit
  effective_from date
  effective_to date
}

Table modifier {
  modifier_id int [pk, increment]
  code nvarchar(10) [unique]
  description nvarchar(400)
  is_active bit
}

Table pos {
  pos_id int [pk, increment]
  code nvarchar(5) [unique]
  description nvarchar(200)
}

Table user_account {
  user_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  username nvarchar(80) [unique]
  email nvarchar(150)
  hashed_password nvarchar(200)
  role_id int [ref: > role.role_id]
  is_client bit
  is_active bit
  created_at datetime
  last_login datetime
}

Table role {
  role_id int [pk, increment]
  role_name nvarchar(80)
  description nvarchar(200)
}

/////////////////////////////
// Scheduling & Encounters
/////////////////////////////

Table appointment {
  appointment_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  patient_id int [ref: > patient.patient_id]
  provider_id int [ref: > provider.provider_id]
  facility_id int [ref: > facility.facility_id]
  start_datetime datetime
  end_datetime datetime
  appointment_type nvarchar(100)
  reason nvarchar(200)
  pos_id int [ref: > pos.pos_id]
  created_at datetime
}

Table encounter {
  encounter_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  patient_id int [ref: > patient.patient_id]
  provider_id int [ref: > provider.provider_id]
  facility_id int [ref: > facility.facility_id]
  appointment_id bigint [ref: > appointment.appointment_id]
  date_of_service_from datetime
  date_of_service_to datetime
  pos_id int [ref: > pos.pos_id]
  status nvarchar(50) // draft, finalized, submitted
  created_at datetime
  updated_at datetime
  authorization_id bigint // optional link if auth captured on encounter
}

Table encounter_diagnosis {
  encounter_id bigint [ref: > encounter.encounter_id]
  icd10_id int [ref: > icd10.icd10_id]
  list_sequence int
  Primary Key (encounter_id, icd10_id, list_sequence)
}

Table encounter_procedure {
  encounter_procedure_id bigint [pk, increment]
  encounter_id bigint [ref: > encounter.encounter_id]
  cpt_id int [ref: > cpt.cpt_id]
  quantity int
  modifier1_id int [ref: > modifier.modifier_id]
  modifier2_id int [ref: > modifier.modifier_id]
  modifier3_id int [ref: > modifier.modifier_id]
  modifier4_id int [ref: > modifier.modifier_id]
  service_from datetime
  service_to datetime
  charge_amount decimal(18,2)
  comments nvarchar(1000)
  revenue_code nvarchar(10)
}

/////////////////////////////
// Prior Authorization (EPA)
/////////////////////////////

Table auth_status {
  status_id int [pk, increment]
  status_desc nvarchar(100) // Initiated, Submitted, Approved, Denied, No-Auth-Required, Cancelled
  is_active bit
}

Table auth_request {
  auth_request_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  patient_id int [ref: > patient.patient_id]
  provider_id int [ref: > provider.provider_id]
  facility_id int [ref: > facility.facility_id]
  payer_plan_id int [ref: > payer_plan.payer_plan_id]
  created_by int [ref: > user_account.user_id]
  created_at datetime
  status_id int [ref: > auth_status.status_id]
  priority nvarchar(30) // Routine/STAT
  appointment_id bigint [ref: - appointment.appointment_id]
  notes nvarchar(2000)
}

Table auth_request_procedure {
  auth_request_id bigint [ref: > auth_request.auth_request_id]
  cpt_id int [ref: > cpt.cpt_id]
  diagnosis_icd10_id int [ref: > icd10.icd10_id]
  units int
  pos_id int [ref: > pos.pos_id]
  modifiers nvarchar(20)
  Primary Key (auth_request_id, cpt_id, diagnosis_icd10_id)
}

Table authorization {
  authorization_id bigint [pk, increment]
  auth_request_id bigint [ref: > auth_request.auth_request_id]
  auth_number nvarchar(100)
  status_id int [ref: > auth_status.status_id]
  valid_from datetime
  valid_to datetime
  visits_authorized int
  document_uri nvarchar(500)
  updated_at datetime
}

/////////////////////////////
// Claims & Payments
/////////////////////////////

Table claim_status {
  claim_status_id int [pk, increment]
  claim_status nvarchar(60) // Submitted, Paid, Denied, No-Response, Patient-Responsibility, Rejected
  is_active bit
}

Table claim {
  claim_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  patient_id int [ref: > patient.patient_id]
  encounter_id bigint [ref: > encounter.encounter_id]
  payer_plan_id int [ref: > payer_plan.payer_plan_id]
  insurance_policy_id int [ref: > insurance_policy.insurance_policy_id]
  claim_status_id int [ref: > claim_status.claim_status_id]
  place_of_service_id int [ref: > pos.pos_id]
  service_from datetime
  service_to datetime
  admit_date datetime
  created_by int [ref: > user_account.user_id]
  created_at datetime
  updated_at datetime
  notes nvarchar(1000)
  clearinghouse_payer_id int [ref: > clearinghouse_payer.clearinghouse_payer_id]
}

Table claim_line {
  claim_line_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  encounter_procedure_id bigint [ref: > encounter_procedure.encounter_procedure_id]
  cpt_id int [ref: > cpt.cpt_id]
  modifier1_id int [ref: > modifier.modifier_id]
  modifier2_id int [ref: > modifier.modifier_id]
  modifier3_id int [ref: > modifier.modifier_id]
  modifier4_id int [ref: > modifier.modifier_id]
  diagnosis_pointer1 int
  diagnosis_pointer2 int
  diagnosis_pointer3 int
  diagnosis_pointer4 int
  charge_amount decimal(18,2)
  allowed_amount decimal(18,2)
  paid_amount decimal(18,2)
  units int
  revenue_code nvarchar(10)
}

Table payment {
  payment_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  claim_line_id bigint [ref: > claim_line.claim_line_id]
  payer_id int [ref: > payer.payer_id]
  check_id nvarchar(80)
  posting_date datetime
  allowed_amount decimal(18,2)
  paid_amount decimal(18,2)
  contractual_adjustment decimal(18,2)
  patient_responsibility decimal(18,2)
  payment_method_type_id int [ref: > payment_method_type.payment_method_type_id]
  description nvarchar(200)
  note nvarchar(500)
}

Table payment_method_type {
  payment_method_type_id int [pk, increment]
  name nvarchar(80) // Cash, Check, EFT, CreditCard
  description nvarchar(200)
}

Table payment_authorization {
  payment_authorization_id bigint [pk, increment]
  payment_id bigint [ref: > payment.payment_id]
  transaction_id nvarchar(80)
  amount decimal(18,2)
  authorization_number nvarchar(80)
  success bit
  response_code nvarchar(20)
  created_at datetime
}

Table refund {
  refund_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  recipient_type nvarchar(20) // patient/payer
  recipient_id bigint
  posting_date datetime
  refund_amount decimal(18,2)
  payment_method nvarchar(40)
  reference_number nvarchar(80)
  status nvarchar(40)
  created_at datetime
  updated_at datetime
}

Table refund_to_payment {
  refund_to_payment_id bigint [pk, increment]
  refund_id bigint [ref: > refund.refund_id]
  payment_id bigint [ref: > payment.payment_id]
  amount decimal(18,2)
  posting_date datetime
}

Table adjustment_reason {
  adjustment_reason_code nvarchar(20) [pk]
  description nvarchar(200)
  is_active bit
}

Table adjustment {
  adjustment_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  claim_line_id bigint [ref: > claim_line.claim_line_id]
  adjustment_reason_code nvarchar(20) [ref: > adjustment_reason.adjustment_reason_code]
  amount decimal(18,2)
  created_at datetime
  notes nvarchar(200)
}

/////////////////////////////
// Denials & Crosswalks
/////////////////////////////

Table denial_master {
  denial_id int [pk, increment]
  denial_code nvarchar(20)
  description nvarchar(500)
  is_carc bit
  is_rarc bit
  active bit
  group_code nvarchar(10)
}

Table claim_denial {
  claim_denial_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  claim_line_id bigint [ref: > claim_line.claim_line_id]
  denial_id int [ref: > denial_master.denial_id]
  posted_at datetime
  notes nvarchar(1000)
}

Table crosswalk_category {
  crosswalk_category_id int [pk, increment]
  category_name nvarchar(100)
  category_desc nvarchar(300)
}

Table crosswalk_status {
  crosswalk_status_id int [pk, increment]
  crosswalk_status nvarchar(120)
  description nvarchar(300)
  crosswalk_category_id int [ref: > crosswalk_category.crosswalk_category_id]
}

Table user_claim_action_status {
  user_claim_action_status_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  user_id int [ref: > user_account.user_id]
  action_id int
  notes nvarchar(2000)
  action_type nvarchar(20) // phone/web
  start_time datetime
  end_time datetime
  state_time datetime
  claim_action_reason_id int [ref: > claim_action_reason.claim_action_reason_id]
}

Table claim_action_reason {
  claim_action_reason_id int [pk, increment]
  reason_desc nvarchar(200)
  claim_stage_id int
}

/////////////////////////////
// Clearinghouse & Enrollments
/////////////////////////////

Table clearinghouse_payer {
  clearinghouse_payer_id int [pk, increment]
  name nvarchar(200)
  clearinghouse_id nvarchar(50)
  eclaims_supported bit
  eras_supported bit
  is_enrollment_required bit
  is_government bit
  is_institutional bit
  is_paper_only bit
  is_participating bit
  is_test_required bit
  is_modified_payer bit
  is_workers_comp_auto bit
  name_transmitted nvarchar(200)
  state_specific nvarchar(50)
}

Table clearinghouse_response {
  clearinghouse_response_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  payment_id bigint [ref: > payment.payment_id]
  response_type nvarchar(80)
  report_type nvarchar(80)
  source_name nvarchar(120)
  source_address nvarchar(200)
  title nvarchar(200)
  file_name nvarchar(200)
  file_received_at datetime
  item_count int
  denied bit
  rejected bit
  total_amount decimal(18,2)
  reviewed bit
  file_contents varbinary(max)
}

Table payer_enrollment {
  payer_enrollment_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  clearinghouse_payer_id int [ref: > clearinghouse_payer.clearinghouse_payer_id]
  payer_id int [ref: > payer.payer_id]
  insurance_program_code nvarchar(40)
  eclaims_selected bit
  eligibility_selected bit
  era_selected bit
  ptan nvarchar(40)
  created_at datetime
  updated_at datetime
}

Table practice_to_insurance_company {
  practice_to_insurance_company_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  payer_id int [ref: > payer.payer_id]
  eclaims_disable bit
  is_enrollable bit
  use_secondary_electronic_billing bit
  enrollment_status_name nvarchar(80)
  created_at datetime
  updated_at datetime
}

Table practice_insurance_group_number {
  practice_insurance_group_number_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  payer_id int [ref: > payer.payer_id]
  payer_plan_id int [ref: > payer_plan.payer_plan_id]
  service_location_id int [ref: > facility.facility_id]
  group_number nvarchar(40)
  billing_number_scope nvarchar(50)
  created_at datetime
}

/////////////////////////////
// Claim Settings & Transactions
/////////////////////////////

Table claim_settings {
  claim_settings_id bigint [pk, increment]
  practice_id int [ref: > practice.practice_id]
  provider_id int [ref: > provider.provider_id]
  facility_id int [ref: > facility.facility_id]
  payer_id int [ref: > payer.payer_id]
  field_17a_number_type nvarchar(40)
  field_17a_value nvarchar(80)
  field_24j_number_type nvarchar(40)
  field_24j_value nvarchar(80)
  field_31_number_type nvarchar(40)
  field_31_value nvarchar(80)
  field_33b_number_type nvarchar(40)
  field_33b_value nvarchar(80)
  taxonomy_code nvarchar(40)
  submitter_number nvarchar(40)
  npi_override nvarchar(40)
  taxid_override nvarchar(40)
  payto_override_name nvarchar(150)
  payto_override_address1 nvarchar(200)
  payto_override_city nvarchar(80)
  payto_override_state nvarchar(2)
  payto_override_zip nvarchar(15)
  created_at datetime
  updated_at datetime
}

Table claim_transaction_type {
  claim_transaction_type_code nvarchar(20) [pk]
  name nvarchar(80)
}

Table claim_transaction {
  claim_transaction_id bigint [pk, increment]
  claim_id bigint [ref: > claim.claim_id]
  claim_line_id bigint [ref: > claim_line.claim_line_id]
  payment_id bigint [ref: > payment.payment_id]
  adjustment_reason_code nvarchar(20) [ref: > adjustment_reason.adjustment_reason_code]
  type_code nvarchar(20) [ref: > claim_transaction_type.claim_transaction_type_code]
  amount decimal(18,2)
  quantity int
  posting_date datetime
  notes nvarchar(400)
  reversible bit
  created_at datetime
}

Table remittance_remark {
  remittance_id int [pk, increment]
  code nvarchar(20)
  description nvarchar(400)
}

/////////////////////////////
// Fee Schedules / Contracts (optional)
/////////////////////////////

Table standard_fee_schedule {
  standard_fee_schedule_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  medicare_rvu_batch_id int
  name nvarchar(120)
  notes nvarchar(400)
  effective_start date
  add_percent decimal(9,4)
}

Table standard_fee {
  standard_fee_id int [pk, increment]
  standard_fee_schedule_id int [ref: > standard_fee_schedule.standard_fee_schedule_id]
  cpt_id int [ref: > cpt.cpt_id]
  modifier_id int [ref: > modifier.modifier_id]
  set_fee decimal(18,2)
  anesthesia_base_units decimal(8,2)
}

Table contract_rate_schedule {
  contract_rate_schedule_id int [pk, increment]
  practice_id int [ref: > practice.practice_id]
  payer_id int [ref: > payer.payer_id]
  medicare_rvu_batch_id int
  effective_start date
  effective_end date
  add_percent decimal(9,4)
  source_file_name nvarchar(200)
}

Table contract_rate {
  contract_rate_id int [pk, increment]
  contract_rate_schedule_id int [ref: > contract_rate_schedule.contract_rate_schedule_id]
  cpt_id int [ref: > cpt.cpt_id]
  modifier_id int [ref: > modifier.modifier_id]
  set_fee decimal(18,2)
  anesthesia_base_units decimal(8,2)
}

/////////////////////////////
// Documents, Faxes, Work
/////////////////////////////

Table document_store {
  document_id bigint [pk, increment]
  owner_type nvarchar(30) // 'order','auth','claim','encounter','patient'
  owner_id bigint
  document_type nvarchar(80)
  file_uri nvarchar(1000)
  uploaded_by int [ref: > user_account.user_id]
  uploaded_at datetime
  is_active bit
}

Table fax_log {
  fax_id bigint [pk, increment]
  from_number nvarchar(50)
  to_number nvarchar(50)
  to_name nvarchar(100)
  subject nvarchar(150)
  sent_at datetime
  file_uri nvarchar(500)
  related_type nvarchar(30) // 'auth_request','authorization','claim'
  related_id bigint
}

Table work_item {
  work_item_id bigint [pk, increment]
  app_area nvarchar(30) // 'EPA','DENIAL','CE'
  entity_type nvarchar(30) // 'auth_request','claim','encounter'
  entity_id bigint
  assigned_user_id int [ref: > user_account.user_id]
  pool_id int
  status nvarchar(40)
  priority nvarchar(20)
  created_at datetime
  updated_at datetime
}

Table pool {
  pool_id int [pk, increment]
  pool_name nvarchar(120)
  payer_id int [ref: > payer.payer_id]
  practice_id int [ref: > practice.practice_id]
}
