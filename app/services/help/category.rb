module Help
  class Category
    attr_accessor :subject, :other_subject

    def initialize(subject, other_subject)
      @subject = subject
      @other_subject = other_subject
    end

    def categorize
      type =
        if @subject.try(:include?, 'Consulta') || @subject.try(:include?, 'Duda')
          return 'problem' if inspect(['no se', 'cancelar', 'problema'])
          return 'incident' if inspect(['notificar'])
          'question'
        elsif @subject.try(:include?, 'Cancelar')
          'problem'
        else
          'incident'
        end

      type
    end

    private

    def inspect(arry = [])
      to_inspec = []
      arry.each do |perhaps|
        to_inspec << @other_subject.downcase.try(:include?, perhaps)
      end
      to_inspec.include?(true)
    end
  end
end
