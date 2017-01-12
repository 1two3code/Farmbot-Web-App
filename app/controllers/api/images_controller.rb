module Api
  class ImagesController < Api::AbstractController
    BUCKET = ENV.fetch("GCS_BUCKET") { raise "You need to set ENV['GCS_BUCKET']"}
    KEY    = ENV.fetch("GCS_KEY") { raise "You need to set ENV['GCS_KEY']"}
    SECRET = ENV.fetch("GCS_ID") { raise "You need to set ENV['GCS_ID']"}

    if (!Rails.env.production?)
      skip_before_action :authenticate_user!, only: [:storage_auth]
      puts "REMOVE THIS NOW!"
    end

    def create
        mutate Images::Create.run({device: current_device}, raw_json)
    end

    def show
      render json: image
    end

    def destroy
      render json: image.destroy! && ""
    end

    def storage_auth
      # Creates a 1 hour authorization for a user to upload an image file to a
      # Google Cloud Storage bucket.
      # You probably want to POST that URL to Images#Create after that.
      render json: {
        verb:    "POST",
        url:     "//storage.googleapis.com/#{BUCKET}",
        headers: {
          "success_action_status" => 201,
          "key"                   => "#{SecureRandom.uuid}.jpg",
          "acl"                   => "public-read",
          "Content-Type"          => "image/jpeg",
          "policy"                => policy,
          "signature"             => policy_signature,
          "GoogleAccessId"        => KEY,
          "file"                  => "REPLACE_THIS_WITH_A_BINARY_JPEG_FILE",
        }
      }
    end

  private

    def policy
      Base64.encode64(
        { 'expiration' => 1.hour.from_now.utc.xmlschema,
          'conditions' => [
           { 'bucket' =>  BUCKET },
           ['starts-with', '$key', ''],
           { 'acl' => 'public-read' },
           { success_action_status: '201' },
           ['starts-with', '$Content-Type', ''],
           ['content-length-range', 1, 4.megabytes]
         ]}.to_json).gsub(/\n/, '')
    end

    def policy_signature
      Base64.encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'),
        SECRET,
        s3_upload_policy)).gsub("\n",'')
    end

    def image
      Image.where(device: current_device).find(params[:id])
    end
  end
end