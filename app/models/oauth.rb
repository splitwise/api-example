class Array
    def sortBy! &iterator
        self.sort! do |a, b|
            iterator.call(a) <=> iterator.call(b)
        end
    end
end

class Oauth < ActiveRecord::Base
  
    API_URL = 'https://secure.splitwise.com/api/v3.0/'

    def self.get_current_user access_token
        JSON.parse(access_token.get(API_URL+'get_current_user').body)
    end

    def self.get_current_user_id access_token
        get_current_user(access_token)['user']['id']
    end

    def self.get_expenses access_token
        JSON.parse(access_token.get(API_URL+'get_expenses').body)
    end

    def self.each_expense_and_share access_token, &block
        id = get_current_user_id access_token
        expenses = get_expenses(access_token)['expenses']
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

    def self.get_balance_over_time access_token
        balance = 0
        result = []
        each_expense_and_share access_token do |expense, share|
            balance += share['net_balance'].to_i
            result.push({'date' => expense['updated_at'], 'balance' => balance.to_s})
        end
        result
    end

    def self.get_balance_over_time_google_charts_format access_token
        historical_balance = get_balance_over_time access_token
        historical_balance.collect do |balance|
            [balance['date'], balance['balance']]
        end
    end

    def self.get_expenses_over_time access_token
        expenses = []
        each_expense_and_share access_token do |expense, share|
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

    def self.get_expenses_by_category access_token #Exports in the form {categories: ["foo", "bar", "baz"], rows: [["10:11:12 Jan 6", 13, 84, 29], ...]}
        categoryHash = {}
        rows = []
        each_expense_and_share access_token do |expense, share|
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
        each_expense_and_share access_token do |expense, share|
            expenses.push({
                "date" => expense['updated_at'],
                "net_balance" => share['net_balance']
            })
        end
        expenses
    end
=end

