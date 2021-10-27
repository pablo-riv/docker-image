namespace :salesmen do
  desc ''
  task migrate: :environment do
    kams = [
      { id: 1, slack_id: 'U0EQS8755' },
      { id: 2, slack_id: 'U24GN85EW' },
      { id: 3, slack_id: 'UDXTHBN9H' },
      { id: 6, slack_id: 'UCRU9LALC' },
      { id: 7, slack_id: 'UCRGNK5QR' },
      { id: 8, slack_id: 'UHY7TBSCQ' },
      { id: 9, slack_id: 'UHG2JF4N7' },
      { id: 10, slack_id: 'UHG3D4B99' }
    ]
    kams.each do |kam|
      Salesman.find_by(id: kam[:id]).update(slack_id: kam[:slack_id])
    end
  end
end
