-- Seed 5 common business words into public.word_cards
insert into public.word_cards (
  word, chinese, phonetic, phrase, phrase_cn,
  sentence_en, sentence_cn, related, related_enabled,
  enabled, tags, source
) values
-- 1) contract
(
  'contract', '合同', '/ˈkɒntrækt/', 'sign a contract', '签订合同',
  'We need to sign the contract this week.', '我们需要在本周签订合同。',
  '["agreement","terms","clause","obligation","termination"]'::jsonb, true,
  true, array['business','contract','core'], 'EWC'
),
-- 2) invoice
(
  'invoice', '发票', '/ˈɪnvɔɪs/', 'issue an invoice', '开具发票',
  'Please issue the invoice by Friday.', '请在周五之前开具发票。',
  '["billing","receipt","payment","due","accounts payable"]'::jsonb, true,
  true, array['business','finance','billing'], 'EWC'
),
-- 3) negotiation
(
  'negotiation', '谈判', '/nɪˌɡoʊʃiˈeɪʃn/', 'enter into negotiation', '进入谈判',
  'Both sides agreed to enter into negotiation.', '双方同意进入谈判。',
  '["deal","bargaining","compromise","terms","counteroffer"]'::jsonb, true,
  true, array['business','strategy','sales'], 'EWC'
),
-- 4) deadline
(
  'deadline', '截止日期', '/ˈdɛdlaɪn/', 'meet the deadline', '赶在截止日期完成',
  'The team must meet the deadline.', '团队必须按时完成。',
  '["due date","timeline","milestone","schedule","ETA"]'::jsonb, true,
  true, array['business','project','time'], 'EWC'
),
-- 5) budget
(
  'budget', '预算', '/ˈbʌdʒɪt/', 'allocate budget', '分配预算',
  'We will allocate more budget to marketing.', '我们将为市场投放分配更多预算。',
  '["cost","expense","forecast","capex","opex"]'::jsonb, true,
  true, array['business','finance','planning'], 'EWC'
);