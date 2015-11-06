class OrdersController < ApplicationController
  responders :flash
  respond_to :html

  before_action :find_order, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    # params[:date] = params[:date].present? ? params[:date].to_datetime.in_time_zone('Moscow').end_of_day : DateTime.now
    params[:date] = params[:date].present? ? params[:date].to_datetime.end_of_day : DateTime.now
    @date = params[:date]
    @orders = Order.filter(params.slice(:date, :organization))
    @orders = @orders.where(user: current_user) unless current_user.admin?

    @day_menu = DayMenu.actual(params[:date])

    respond_with @orders
  end

  def new
    @order = Order.new
    @date = DateTime.now
    @items = DayMenu.actual(@date).items

    respond_with @order
  end

  def create
    @order = current_user.orders.build(order_params)
    @date = DateTime.now
    @items = DayMenu.actual(@date).items

    @order.save
    respond_with @order, location: orders_path
  end

  def edit
  end

  def update
    # if @order.update(order_params)
    #   redirect_to hotel_path(@order)
    # else
    #   render 'edit'
    # end
  end

  def destroy
    # if @order.destroy
    #   flash[:success] = "Hotel deleted successfully!"
    #   redirect_to hotels_path
    # else
    #   redirect_to hotel_path(@order)
    # end
  end

  private

    def order_params
      params.require(:order).permit(
                                    :item_ids => []
                                    )
    end

    def find_order
      # @order = Order.find(params[:id])
    end

end
