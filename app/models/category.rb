class Category < ActiveRecord::Base
    
    has_many :discussions
    
    validates_presence_of :name
    
    acts_as_list
    
    after_save do |category|
        Discussion.update_all("trusted = " + (category.trusted? ? '1' : '0'), "category_id = #{category.id}")
    end
    
    class << self

        # Enable work safe URLs
        def work_safe_urls=(state)
            @@work_safe_urls = state
        end

        def work_safe_urls
            @@work_safe_urls ||= false
        end

    end

    def viewable_by?(user)
        (user && !(self.trusted? && !(user.trusted? || user.admin?))) ? true : false
    end
    
    # Humanized ID for URLs
    def to_param
        slug = self.name
        slug = slug.gsub(/[\[\{]/,'(')
        slug = slug.gsub(/[\]\}]/,')')
        slug = slug.gsub(/[^\w\d!$&'()*,;=\-]+/,'-').gsub(/[\-]{2,}/,'-').gsub(/(^\-|\-$)/,'')
        (Discussion.work_safe_urls) ? self.id : "#{self.id};" + slug
    end
    
	def fix_counter_cache!
		if discussions_count != discussions.count
			logger.warn "counter_cache error detected on Category ##{self.id} (discussions)"
			Category.update_counters(self.id, :discussions_count => (discussions.count - discussions_count) )
		end
	end
end
