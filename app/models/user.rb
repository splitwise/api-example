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

    ['get_current_user', 'get_expenses'].each do |method|
        define_method method.to_sym do
            JSON.parse(@access_token.get(API_URL+method+"?limit=250&visible=true").body)
        end
    end

    def get_current_user_id
        get_current_user['user']['id']
    end

    def each_expense &block
        expenses = get_expenses['expenses'].each &block
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

    def get_balance_over_time
        balance = 0
        result = []
        each_expense_and_share do |expense, share|
            balance += share['net_balance'].to_f
            result.push({'date' => expense['date'], 'balance' => balance.to_s})
        end
        result
    end

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

    def get_balance_over_time_google_charts_format 
        historical_balance = get_balance_over_time
        historical_balance.collect do |balance|
            [balance['date'], balance['balance']]
        end
    end

    def get_expenses_over_time 
        expenses = []
        each_expense_and_share do |expense, share|
            expenses.push({
                "date" => expense['date'],
                "expense" => share['owed_share']   
            })
        end
        expenses.sort! do |a, b|
            a['date'] <=> b['date']
        end
        expenses
    end

    def get_expenses_over_time_cumulative
        total = 0
        expenses = get_expenses_over_time
        expenses.each do |e|
            e['expense'] = total = e['expense'].to_f + total
        end
        expenses
    end

    def get_expenses_over_time_by_category #Exports in the form {categories: ["foo", "bar", "baz"], rows: [["10:11:12 Jan 6", 13, 84, 29], ...]}
        categoryHash = {}
        rows = []
        each_expense_and_share do |expense, share|
            rows.push({
                'date' => expense['date'],
                expense['category']['name'] => share['owed_share']
            })
            categoryHash[expense['category']['name']] = true
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

    def get_expenses_matching query
        expenses = []
        processed_query = query.gsub(/[^a-zA-Z]/, ' ').split(/\ +/)
        each_expense_and_share do |expense, share|
            if processed_query.select { |q| 
                    (expenses['description'] + ' ' + expenses['category']['name']).match(q)
                }.length == processed_query.length
                expenses.push({
                    "date" => expense['date'],
                    "expense" => share['owed_share']   
                })
            end
        end
        expenses.sort! do |a, b|
            a['date'] <=> b['date']
        end
        expenses
    end

    def get_expenses_cumulative_matching query
        total = 0
        expenses = get_expenses_matching query
        expenses.each do |e|
            e['expense'] = total = e['expense'].to_f + total
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

