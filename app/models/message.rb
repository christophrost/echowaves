class Message < ActiveRecord::Base

  belongs_to :conversation
  belongs_to :user
  
  # FIXME: should this really have a double association to the same model?
  has_many :abuse_reports
  belongs_to :abuse_report
  
  has_many :conversations, # these are the conversations spawned from the message
           :foreign_key => "parent_message_id"

  has_attached_file :attachment,
    :styles => {
      :thumb => "64x64>",
      :small => "150x150>",
      :big   => "400x400>" 
    },
    :path => PAPERCLIP_PATH,
    :url  => PAPERCLIP_URL
  
  named_scope :published, :conditions => { :abuse_report_id => nil }

  define_index do
    indexes created_at, :sortable => true
    indexes message
  end
          
  validates_attachment_size :attachment, :less_than => 5.megabytes
  validates_attachment_content_type :attachment, :content_type => [ 'application/pdf', 'application/x-pdf', 'application/x-download', 'application/rtf', 'image/gif', 'image/jpeg', 'image/png', 'image/tiff', 'image/rgb' ]
  
  validates_presence_of :user_id, :conversation_id, :message

  # expected to return a new spawned conversation
  def spawn_new_conversation(user)
    name = (user.login + " spawned from: " + message)[0,100] # FIXME: the convo name length is limited to 100, do not remove this range -- will fails otherwise
    user.conversations.create(:description => self.message, :parent_message_id => self.id, :name => name)
  end

  def over_abuse_reports_limit?
    self.abuse_reports.size > MESSAGE_ABUSE_THRESHOLD
  end

  # add an abuse report per user
  def report_abuse(user)
    unless abuse_report = self.abuse_reports.find_by_user_id(user.id)
      abuse_report = self.abuse_reports.create(:user => user)
    end
    self.reload

    # check if we need to deactivate the message for abuse
    if (user == self.conversation.owner) or self.over_abuse_reports_limit?
      self.update_attributes(:abuse_report => abuse_report)

      # FIXME: why is this next line happening?  There has to be a better way to accomplish whatever is trying to be accomplished then issuing a system call!
      #        we need to take all OS setups into account, not just unix
      # perhaps this line is really important in publicly installed site like http://echowaves.com. could be parameterized for local installs
      system "chmod -R 000 ./public/attachments/#{message.id}"
    end
  end

  def after_create 
    unless subscription = Subscription.find_by_user_id_and_conversation_id(user.id, conversation.id)
      subscription = user.subscriptions.create(:conversation => conversation) 
    end
    subscription.mark_read
  end

  
end
