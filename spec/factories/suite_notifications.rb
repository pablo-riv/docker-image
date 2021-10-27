FactoryBot.define do
  factory :suite_notification do
    source { 4 }
    status { 0 }
    account { 1 }
  end
end
