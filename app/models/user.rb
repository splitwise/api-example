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
            JSON.parse(@access_token.get(API_URL+method).body)
        end
    end

    def get_current_user_id
        get_current_user['user']['id']
    end

    def each_expense_and_share &block
        id = get_current_user_id 
        expenses = get_expenses['expenses']
        expenses.sortBy! do |expense|
            expense['updated_at']
        end
        expenses.collect! do |expense|
            users = expense['users'].select do |share| 
                next share['user']['id'] == id 
            end
            if users.length == 1
                share = users[0]
            else
                throw "Found not one but #{users.length} users!"
            end
            block.call(expense, share)
        end
    end

    def get_balance_over_time
        balance = 0
        result = []
        each_expense_and_share do |expense, share|
            balance += share['net_balance'].to_i
            result.push({'date' => expense['updated_at'], 'balance' => balance.to_s})
        end
        result
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
                "date" => expense['updated_at'],
                "expense" => share['owed_share']   
            })
        end
        expenses.sort! do |a, b|
            a['date'] <=> b['date']
        end
        expenses
    end

    def get_expenses_by_category #Exports in the form {categories: ["foo", "bar", "baz"], rows: [["10:11:12 Jan 6", 13, 84, 29], ...]}
        categoryHash = {}
        rows = []
        each_expense_and_share do |expense, share|
            rows.push({
                'date' => expense['updated_at'],
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
end


































#No longer useful:
=begin
    def self.get_net_balances_over_time access_token
        expenses = []
        each_expense_and_share do |expense, share|
            expenses.push({
                "date" => expense['updated_at'],
                "net_balance" => share['net_balance']
            })
        end
        expenses
    end
=end

