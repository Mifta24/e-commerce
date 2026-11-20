Rails.application.config.x.payment.bank_name      = ENV.fetch("PAYMENT_BANK_NAME", "BCA")
Rails.application.config.x.payment.account_number = ENV.fetch("PAYMENT_ACCOUNT_NUMBER", "0000000000")
Rails.application.config.x.payment.account_holder = ENV.fetch("PAYMENT_ACCOUNT_HOLDER", "Nama Pemilik Rekening")
Rails.application.config.x.payment.deadline_hours = ENV.fetch("PAYMENT_DEADLINE_HOURS", "24").to_i
