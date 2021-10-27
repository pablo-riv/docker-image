class ShippifyService
  include HTTParty
  base_uri 'https://api.shippify.co'
  headers 'Authorization' => "Basic #{Base64.encode64('iwdmlp4n030nowt8zv706bt9:iwdmlp54n3y833di').delete("\n")}"
  headers 'Content-Type' => 'application/json'

  def create_task(task)
    self.class.post('/task/new', body: task.to_json)
  rescue => e
    e.message
  end

  def show_task(id)
    self.class.get("/task/info/#{id}", headers: @headers)
  rescue => e
    e.message
  end

  def task
    {
      task: { # Task object. (object)
        products: [ # Product list attached to task. (array)
          name:  '', # Product name. (string)
          qty: 0, # Total amount of similar products. (int)
          size: '' # Product size based on vehicle size chart: 1 - Bicycle, 2 - Motorcycle, 3 - Car, 4 - SUV, 5 - Truck.. (int) (shippify-package-size)
        ],
        sender: { # Customer object sending the package. (object)
          email: '' # Customer email address. (string)
        },
        recipient: { # Customer object receiving the package. (object)
          # All customer objects must have at the bare minimum an email address or phone number associated to it.
          name: '', # Customer name. (string) (optional)
          email: '', # Customer email address. (string)
          phone: '' # Customer phone number. (string)
        },
        pickup: { # Pickup location object. (object)
          lat: '', # Location latitude. (double)
          lng: '', # Location longitude. (double)
          address: '', # Location physical address. (string)
        },
        # Pickup time must be less than delivery time
        pickup_date: (Time.now + 1.hours).to_time.to_i, # Estimated pickup date. (default=now + 1 hour) (double) (unix-timestamp)
        deliver: { # Delivery location object. (object)
          lat: '', # Location latitude. (double)
          lng: '', # Location longitude. (double)
          address: '', # Location physical address. (string)
        },
        # Delivery time must be greater than pickup time
        delivery_date: (Time.now + 4.hours).to_time.to_i, # Estimated pickup date. (default=pickup_date + 3 hour) (double) (unix-timestamp)
        total_amount: '', #  Total amount charged by the shipper in cash, if the recipient did not pay before via bank transfer or credit card online. (double) (optional)
        payment_type: 2, #  Task payment type from payment chart: 1 - Credit, 2 - Cash, 3 - Bank transfer, 4 - Debit, 5 - Boleto. (int) (default=1)
        payment_status: 0, #  Task payment status from payment chart: 1 - Prepaid, 2 - Paid on reception. (int) (default=1)
        # extra: { # JSON string for additional data given by the developer for their own use. (string) (json)
        #   pk_note: '', # Pickup extra information. (string) (optional)
        #   note: '', # Delivery extra information. (string) (optional)
        #   custom_developer_label: '' # Developer label key , value metadata
        # },
        ref_id: '', # Reference ID to index this task with an ID from your system. Used for integrations with other platforms (string)(optional).
        # send_email_params: { # Tracking email configuration for client. (string) (json) (optional)
        #   from: 'hirochi@shipit.cl', # Company name or email. (string)
        #   subject: 'Estado del pedido', # Email subject. (string)
        #   to: 'michel@shipit.cl' # Client email. (string)
        # }
      }
    }
  end
end
