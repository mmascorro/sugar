# encoding: utf-8

class Discussion < Exchange
  include SearchableExchange
  include Viewable

  has_many :discussion_relationships, dependent: :destroy

  scope :for_view, -> { sorted.with_posters }

  after_save :update_trusted_status

  class << self
    def popular_in_the_last(days=7.days)
      joins(:posts)
        .where('posts.created_at > ?', days.ago)
        .group('exchanges.id')
        .order('COUNT(posts.id) DESC')
    end
  end

  # Converts a discussion to a conversation
  def convert_to_conversation!
    if self.valid?
      self.transaction do
        self.update_attributes(type: "Conversation")
        self.becomes(Conversation).tap do |conversation|
          conversation.update_attributes(trusted: false, sticky: false, closed: false, nsfw: false)
          self.posts.update_all(conversation: true, trusted: false)
          self.participants.each do |participant|
            conversation.add_participant(participant)
          end
          self.discussion_relationships.destroy_all
        end
      end
    end
  end

  def participants
    User.find_by_sql(
      "SELECT u.*, MAX(p.created_at) AS last_post_at " +
      "FROM users u, posts p " +
      "WHERE p.exchange_id = #{self.id} AND p.user_id = u.id " +
      "GROUP BY u.id "
    )
  end

  def editable_by?(user)
    (user && (user.moderator? || user == self.poster)) ? true : false
  end

  def postable_by?(user)
    (user && (user.moderator? || !self.closed?)) ? true : false
  end

  private

  def update_trusted_status
    if self.trusted_changed?
      self.posts.update_all(trusted: self.trusted?)
      self.discussion_relationships.update_all(trusted: self.trusted?)
      self.participants.each do |user|
        user.update_column(:public_posts_count, user.discussion_posts.where(trusted: false).count)
      end
    end
  end

end
