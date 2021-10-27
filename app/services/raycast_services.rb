module RaycastServices
  class Calc
    def self.contains?(bounds, lat, lng)
      count = bounds.map.with_index do |_bound, index|
        v1 = bounds[index]
        v2 = bounds[(index + 1) % bounds.length]
        1 if west(v1, v2, lat, lng)
      end
      count.compact.sum % 2
    rescue NoMethodError => e
      puts e.message.to_s.red
    end

    def self.west(a, b, x, y)
      if a['longitude'] <= b['longitude']
        if y <= a['longitude'] || y > b['longitude'] || x >= a['latitude'] && x >= b['latitude']
          false
        elsif x < b['latitude'] && x < b['latitude']
          true
        else
          (y - a['longitude']) / (x - a['latitude']) > (b['longitude'] - a['longitude']) / (b['latitude'] - a['latitude'])
        end
      else
        west(b, a, x, y)
      end
    end
  end
end
