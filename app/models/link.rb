class Link < ActiveRecord::Base
  belongs_to :link_type,    :class_name => 'Link::Type'
  belongs_to :link_object,  :class_name => 'Link::Object'

  @map = {
    'normal' => 'normal',
    'parent' => 'child',
    'child'  => 'parent',
  }

=begin

  Link.list(
    :link_object       => 'Ticket',
    :link_object_value => 1
  )
 
=end

  def self.list(data)
    linkobject = self.link_object_get( :name => data[:link_object] )
    return if !linkobject
    items = []

    # get links for one site
    list = Link.where(
      'link_object_source_id = ? AND link_object_source_value = ?', linkobject.id, data[:link_object_value]
    )

    list.each { |item|
      link = {}
      link['link_type']         = @map[ Link::Type.find( item.link_type_id ).name ]
      link['link_object']       = Link::Object.find( item.link_object_target_id ).name
      link['link_object_value'] = item.link_object_target_value
      items.push link
    }

    # get links for the other site
    list = Link.where(
      'link_object_target_id = ? AND link_object_target_value = ?', linkobject.id, data[:link_object_value]
    )
    list.each { |item|
      link = {}
      link['link_type']         = Link::Type.find( item.link_type_id ).name
      link['link_object']       = Link::Object.find( item.link_object_source_id ).name
      link['link_object_value'] = item.link_object_source_value
      items.push link
    }

    return items
  end

=begin

   Link.add(
    :link_type                => 'normal',
    :link_object_source       => 'Ticket',
    :link_object_source_value => 6,
    :link_object_target       => 'Ticket',
    :link_object_target_value => 31
  )

  Link.add(
    :link_types_id            => 12,
    :link_object_source_id    => 1,
    :link_object_source_value => 1,
    :link_object_target_id    => 1,
    :link_object_target_value => 1
  ) 

=end

  def self.add(data)

    if data.has_key?(:link_type)
      linktype = self.link_type_get( :name => data[:link_type] )
      data[:link_type_id] = linktype.id
      data.delete( :link_type )
    end

    if data.has_key?(:link_object_source)
      linkobject = self.link_object_get( :name => data[:link_object_source] )
      data[:link_object_source_id] = linkobject.id
      data.delete( :link_object_source )
    end

    if data.has_key?(:link_object_target)
      linkobject = self.link_object_get( :name => data[:link_object_target] )
      data[:link_object_target_id] = linkobject.id
      data.delete( :link_object_target )
    end

    Link.create(data)
  end

=begin

   Link.remove(
    :link_type                => 'normal',
    :link_object_source       => 'Ticket',
    :link_object_source_value => 6,
    :link_object_target       => 'Ticket',
    :link_object_target_value => 31
  ) 

=end

  def self.remove(data)
    if data.has_key?(:link_object_source)
      linkobject = self.link_object_get( :name => data[:link_object_source] )
      data[:link_object_source_id] = linkobject.id
    end

    if data.has_key?(:link_object_target)
      linkobject = self.link_object_get( :name => data[:link_object_target] )
      data[:link_object_target_id] = linkobject.id
    end

    # from one site
    if data.has_key?(:link_type)
      linktype = self.link_type_get( :name => data[:link_type] )
      data[:link_type_id] = linktype.id
    end
    links = Link.where(
      :link_type_id             => data[:link_type_id],
      :link_object_source_id    => data[:link_object_source_id],
      :link_object_source_value => data[:link_object_source_value],
      :link_object_target_id    => data[:link_object_target_id],
      :link_object_target_value => data[:link_object_target_value]
    )
    links.each { |link|
      link.destroy
    }

    # from the other site
    if data.has_key?(:link_type)
      linktype = self.link_type_get( :name => @map[ data[:link_type] ] )
      data[:link_type_id] = linktype.id
    end
    links = Link.where(
      :link_type_id             => data[:link_type_id],
      :link_object_target_id    => data[:link_object_source_id],
      :link_object_target_value => data[:link_object_source_value],
      :link_object_source_id    => data[:link_object_target_id],
      :link_object_source_value => data[:link_object_target_value]
    )
    links.each { |link|
      link.destroy
    }
  end

  private
    def self.link_type_get(data)
      linktype = Link::Type.where( :name => data[:name] ).first
      if !linktype
        linktype = Link::Type.create(
          :name => data[:name]
        )
      end
      return linktype
    end

    def self.link_object_get(data)
      linkobject = Link::Object.where( :name => data[:name] ).first
      if !linkobject
        linkobject = Link::Object.create(
          :name => data[:name]
        )
      end
      return linkobject
    end

end

class Link::Type < ActiveRecord::Base
  validates :name, :presence => true
end

class Link::Object < ActiveRecord::Base
  validates :name, :presence => true
end