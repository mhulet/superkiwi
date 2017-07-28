class SalesController < ApplicationController
  require "csv"

  def index
    if params[:code]
      @sales = Sale.where("code ~* ?", "^#{params[:code]}[0-9]+$").order("sold_at DESC").page(1).per(9999)
      @droper = Droper.where(code: params[:code])
      @sales_amount = @sales.sum(:amount).to_f / 100
    else
      @sales = Sale.page(params[:page])
    end
  end

  def destroy
    @sale = Sale.find(params[:id])
    @sale.destroy
    redirect_to sales_url
  end

  def import
    if request.get?
      # render only
    elsif request.post? and params[:file].present?
      @invalid_sale = nil
      execute_import
    end
  end

  def report
    if params[:date].nil?
      render "report_form" and return
    end
    @from_date = Date.parse("#{params[:date][:year]}-#{params[:date][:month]}-01")
    @to_date = @from_date.at_end_of_month
    @sales_count = Sale.where("sold_at >= ? AND sold_at <= ?", @from_date, @to_date).count
    @month_dropers = []
    @dropers_sales = Array.new
    @dropers_sales_total = Array.new
    @droper_sales_commission = Array.new
    @month_income = 0.0
    @month_commissions = 0.0
    seconds_counter = 20
    Droper.all.each do |droper|
      droper_sales = droper.period_sales(@from_date, @to_date)
      if droper_sales.present?
        @month_dropers << droper
        @dropers_sales[droper.id] = droper_sales
        @dropers_sales_total[droper.id] = 0.0
        @droper_sales_commission[droper.id] = 0.0
        droper_sales.each do |sale|
          @dropers_sales_total[droper.id] += sale.amount
          if sale.amount < 10000
            @droper_sales_commission[droper.id] += sale.amount.to_f * 0.5
          else
            @droper_sales_commission[droper.id] += sale.amount.to_f * 0.4
          end
        end
        @month_income += @dropers_sales_total[droper.id]
        @month_commissions += @droper_sales_commission[droper.id]
      end
    end

    respond_to do |format|
      format.html
      format.xml {
        # check for missing IBAN
        dropers_errors = @month_dropers.select { |d| d.commissionnable? and (d.bank_account.nil? or d.bank_account.empty?) }
        if dropers_errors.count > 0 and !params[:debug]
          render xml: "<message>Il y a une erreur avec le compte IBAN de: #{dropers_errors.collect { |d| d.code }.join(',')}</message>", status: :unprocessable_entity
        end
      }
    end
  end

  private

  def execute_import
    infile               = params[:file].read.gsub(/\\"/,'""')
    n                    = 0
    imported_sales_count = 0
    @import_errors       = {}
    CSV.parse(infile, col_sep: ",") do |row|
      n += 1
      next if n == 1 or row.join.blank?
      sale = Sale.build_from_csv(row)
      if sale.valid?
        sale_droper_code = sale.code.upcase.match(/[A-Z]+/).to_s
        droper = Droper.where(code: sale_droper_code)
        if droper.any?
          sale.droper = droper.first
        else
          sale.droper = Droper.create(code: sale_droper_code)
        end
        sale.save
        imported_sales_count += 1
      else
        @import_errors[sale.code] = sale.errors.full_messages
      end
    end
    flash[:notice] = "Ventes importées: #{imported_sales_count} (sur #{n-1} lignes)."
  end
end
