class Array
    def sortBy! &iterator
        self.sort! do |a, b|
            iterator.call(a) <=> iterator.call(b)
        end
    end
end

class User
  
    API_URL = 'https://secure.splitwise.com/api/v3.0/'

    def initialize access_token
        @access_token = access_token
    end

    ['get_current_user', 'get_friends'].each do |method|
        define_method method.to_sym do
            data = @access_token.get(API_URL+method)
            body = data.body
            parsed = JSON.parse(body)
            parsed
        end
    end

    def get_expenses
        JSON.parse(@access_token.get(API_URL+'get_expenses?limit=250&visible=true').body)
    end

    def get_current_user_id
        @id or (@id = get_current_user['user']['id'])
    end

    def get_friend_ids
        id = get_current_user_id
        friend_ids = []
        each_friend do |friend|
            candidates = friend['users'].reject{|u| u['id'] == id}
            throw "I find not 1 but #{candidates.length} other users in a friend." unless candidates.length == 1
            friend_ids.push(candidates[0]['id'])
        end
    end

    def each_expense &block
        expenses = get_expenses['expenses']
        expenses.sortBy! do |expense|
            expense['date']
        end
        expenses.each &block
    end

    def each_expense_newest_to_oldest &block
        expenses = get_expenses['expenses']
        expenses.sort! do |a, b|
            b['date'] <=> a['date']
        end
        expenses.each &block
    end

    def each_expense_and_share &block
        id = get_current_user_id 
        expenses = get_expenses['expenses']
        expenses.sortBy! do |expense|
            expense['date']
        end
        expenses.collect! do |expense|
            users = expense['users'].select do |share| 
                next (share['user'] and share['user']['id'] == id)
            end
            if users.length == 1
                share = users[0]
                block.call(expense, share)
            else
                # TODO: handle expenses not involving the current user
                # throw "Found not one but #{users.length} users!"
            end
        end
    end

    def each_expense_and_share_newest_to_oldest &block
        id = get_current_user_id 
        expenses = get_expenses['expenses']
        expenses.sort! do |a, b|
            b['date'] <=> a['date']
        end
        expenses.collect! do |expense|
            users = expense['users'].select do |share| 
                next (share['user'] and share['user']['id'] == id)
            end
            if users.length == 1
                share = users[0]
                block.call(expense, share)
            else
                # TODO: handle expenses not involving the current user
                # throw "Found not one but #{users.length} users!"
            end
        end
    end

    def each_friend &block
        get_friends['friends'].each &block
    end

=begin
    def each_friend &block
        id = get_current_user_id
        each_friend do |friend|
            candidates = friend['users'].reject{|u| u['id'] == id}
            throw "I find not 1 but #{candidates.length} other users in a friend." unless candidates.length == 1
            block.call(candidates[0])
        end    
    end
=end

    def get_current_balance 
        balance = 0
        each_friend do |friend|
            balance += friend['balance'].inject 0 do |rest, b|
                if b['currency_code'].downcase == 'usd'
                    next rest + b['amount'].to_f
                else
                    next rest
                end
            end
        end
        balance
    end

    def get_balance_over_time
        balance = get_current_balance
        balances = []
        each_expense_and_share_newest_to_oldest do |expense, share|
            balances.push({'date' => expense['date'], 'balance' => balance.to_f})
            balance -= share['net_balance'].to_f
        end
        return balances.reverse
    end

    def get_current_balances_with_friends
        id = get_current_user_id
        d = get_current_user_id
        friends = Hash.new(-1)
        each_friend do |friend|
            candidates = friend['users'].reject{|u| u['id'] == id}
            throw "I find not 1 but #{candidates.length} other users in a friend." unless candidates.length == 1
            friends[candidates[0]['id']] = friend['balance'].to_f
        end
        friends
    end

    def get_balances_over_time_with_friends
        id = get_current_user_id
        current_balances = get_current_balances_with_friends
        friend_keys = current_balances.keys.sort!
        balance_records = []
        each_expense_newest_to_oldest do |expense|
            balance_records.push({
                                    'date' => expense['date'],
                                    'balances' => current_balances.values_at(*friend_keys)
                                 })
            expense['repayments'].each do |repayment|
                if repayment['from'] == id
                    current_balances[repayment['to']] += repayment['amount'].to_f
                elsif repayment['to'] == id
                    current_balances[repayment['from']] -= repayment['amount'].to_f
                end
            end
        end
        friends = []
        each_friend do |friend|
            friends.push(friend)
        end
        {
            'friends' => friends,
            'balances' => balance_records.reverse
        }
    end

    def get_expenses_over_time 
        expenses = []
        each_expense_and_share do |expense, share|
            unless expense['payment']
                expenses.push({
                    "date" => expense['date'],
                    "expense" => share['owed_share'].to_f,
                    "description" => expense['description']
                })
            end
        end
        expenses.sortBy! do |a|
            a['date']
        end
        expenses
    end

    def get_expenses_over_time_cumulative
        total = 0
        expenses = get_expenses_over_time
        expenses.each do |e|
            e['total'] = total = e['expense'] + total
        end
        expenses
    end

    def get_expenses_by_category
        categoryHash = {}
        each_expense_and_share do |expense, share|
            unless expense['payment']
                categoryHash[expense['category']['name']] ||= 0
                categoryHash[expense['category']['name']] += share['owed_share'].to_f
            end
        end
        categoryHash
    end

    def get_expenses_by_category_over_time_cumulative
        id = get_current_user_id
        current_expenses = get_expenses_by_category
        categories = current_expenses.keys.sortBy! do |category|
            -current_expenses[category]
        end
        expenses_records = []
        each_expense_and_share_newest_to_oldest do |expense, share|
            unless expense['payment']
                expenses_records.push({
                                        'date' => expense['date'],
                                        'expenses' => current_expenses.values_at(*categories)
                                     })
                current_expenses[expense['category']['name']] -= share['owed_share'].to_f
            end
        end
        {
            'categories' => categories,
            'expenses' => expenses_records.reverse
        }
    end

    def get_expenses_matching query
        expenses = []
        processed_query = query.gsub(/[^a-zA-Z]/, ' ').split(/\ +/)
        p query
        p processed_query
        each_expense_and_share do |expense, share|
            unless expense['payment']
                if processed_query.select { |q| 
                        (expense['description'] + ' ' + expense['category']['name']).match(q)
                    }.length > 0 or processed_query.length == 0
                    expenses.push({
                        "date" => expense['date'],
                        "expense" => share['owed_share'].to_f,
                        "description" => expense['description'] 
                    })
                end
            end
        end
        expenses.sort! do |a, b|
            a['date'] <=> b['date']
        end
        expenses
    end

    def get_expenses_matching_cumulative query  # returns expenses in the form {'date' => ...,  'description' => ..., 'expense' => ..., 'total' => ...}
        total = 0
        expenses = get_expenses_matching query
        expenses.each do |e|
            e['total'] = total = e['expense'] + total
        end
        expenses
    end
end


































#No longer useful:

=begin
    def self.get_net_balances_over_time access_token
        expenses = []
        each_expense_and_share do |expense, share|
            expenses.push({
                "date" => expense['date'],
                "net_balance" => share['net_balance']
            })
        end
        expenses
    end
=end

=begin
    def get_balances_with_friends
        id = get_current_user_id
        friend_ids = []
        friend_id_to_name = {}
        balances = {}
        each_expense do |expense|
            if balances[expense['date']]
                #throw "I find a date in balances already set!" 
            end
            balances[expense['date']] = []
            expense['repayments'].each do |repayment|
                if repayment['from'] == id
                    index = friend_ids.index(repayment['to']) 
                    unless index
                        index = friend_ids.push(repayment['to']).length - 1
                        friend_id_to_name[friend_ids[index]] = expense['users'].select do |user|
                            user['user_id'] == friend_ids[index]
                        end.first['user']
                    end
                    balances[expense['date']][index] ||= 0
                    balances[expense['date']][index] -= repayment['amount'].to_f
                elsif repayment['to'] == id
                    index = friend_ids.index(repayment['from'])
                    unless index
                        index = friend_ids.push(repayment['from']).length - 1
                        friend_id_to_name[friend_ids[index]] = expense['users'].select do |user|
                            user['user_id'] == friend_ids[index]
                        end.first['user']
                    end
                    balances[expense['date']][index] ||= 0
                    balances[expense['date']][index] += repayment['amount'].to_f
                end
            end
        end
        friends = friend_ids.collect do |id|
            friend_id_to_name[id]
        end
        balances.each do |date, bs|
            new_bs = []
            friend_ids.each_index do |i|
                new_bs[i] = (bs[i] or 0)
            end
            balances[date] = new_bs
        end
        {
            'friends' => friends,
            'balances' => balances
        }
    end

    def get_balances_over_time_with_friends
        d = get_balances_with_friends
        friends = d['friends']
        balanceses = d['balances'].to_a.sortBy! { |key, vals| key }
        cumulative_balances = friends.collect { 0 }
        balanceses.collect! do |date, balances|
            cumulative_balances = cumulative_balances.zip(balances).map { |a, b| a + b }
            [date, cumulative_balances.dup]
        end
        {
            'friends' => friends,
            'balances' => balanceses
        }
    end
=end

=begin
    def get_expenses_by_category_over_time #Exports in the form {categories: ["foo", "bar", "baz"], rows: [["10:11:12 Jan 6", 13, 84, 29], ...]}
        categoryHash = {}
        rows = []
        each_expense_and_share do |expense, share|
            unless expense['payment']
                rows.push({
                    'date' => expense['date'],
                    expense['category']['name'] => share['owed_share']
                })
                categoryHash[expense['category']['name']] = true
            end
        end
        categories = categoryHash.keys
        rows.collect! do |row|
            next {
                'date' => row['date'],
                'expenses' => categories.collect{ |category| row[category] }
            }
        end
        {
            'categories' => categoryHash.keys, 
            'rows' => rows
        }
    end
=end


=begin
    def purge_deleted_friends hash #NB: this modifies the hash.
        hash.delete_if do |key, _|
            key == -1
        end
    end

    private :purge_deleted_friends
=end