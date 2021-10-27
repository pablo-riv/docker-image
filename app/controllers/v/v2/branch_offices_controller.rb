module V
  module V2
    class BranchOfficesController < V::ApplicationController

      api :GET, "/branch_offices", "show all branch_offices avalibles and their details"
      def index
        if params[:is_default].present? && params[:is_default]
          render json: current_account.current_company.branch_offices.where(is_default: true), status: :ok
        else
          render json: current_account.current_company.branch_offices, status: :ok
        end
      end

      api :GET, "/branch_offices/:id", "show an specific branch_office detail"
      param :id, :number, desc: "this is the parameter to filter", required: true
      def show

        if params[:is_default].present? && params[:is_default]
          render json: current_account.current_company.branch_offices.find_by(id: params[:id], is_default: true), status: :ok        
        else
          render json: current_account.current_company.branch_offices.find_by(id: params[:id]), status: :ok
        end
        
      end
      
      api :POST, "/branch_offices", "Create a new branch office"
      def create
        
        params[:branch_office]['is_default'] = true if params[:is_default].present? && params[:is_default]
        branch_office = BranchOffice.build_branch_office_account(params[:branch_office].to_json, current_account.current_company, 'new', true)

        render json: branch_office, status: :ok
      rescue StandardError => e
        puts e.backtrace.join("\n").red
        render json: { error: "Hubo un problema intentando crear la sucursal. #{e.message}" }, status: :bad_request
      end
    end
  end
end