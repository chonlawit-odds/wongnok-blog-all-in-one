class FollowersController < ApplicationController
  # GET /followers/new
  def new
    @follower = Follower.new
  end

  # POST /followers
  def create
    @follower = Follower.new(follower_params)

    if @follower.save
      redirect_to posts_path, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def follower_params
      params.expect(follower: [ :email ])
    end
end
