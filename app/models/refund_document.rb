class RefundDocument < ApplicationRecord
  belongs_to :refund
  has_attached_file :document
  do_not_validate_attachment_file_type :document

  def binary_data
    Paperclip.io_adapters.for(document).read
  end
end
