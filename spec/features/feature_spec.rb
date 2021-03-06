 feature 'Filtering tags' do
   before(:each) do
    Link.create(url: 'http://www.makersacademy.com', title: 'Makers Academy', tags: [Tag.first_or_create(name: 'education')])
    Link.create(url: 'http://www.google.com', title: 'Google', tags: [Tag.first_or_create(name: 'search')])
    Link.create(url: 'http://www.zombo.com', title: 'This is Zombocom', tags: [Tag.first_or_create(name: 'bubbles')])
    Link.create(url: 'http://www.bubble-bobble.com', title: 'Bubble Bobble', tags: [Tag.first_or_create(name: 'bubbles')])
  end
  scenario 'I can filter links by tag' do

    visit '/tags/bubbles'

    expect(page.status_code).to eq(200)
    within 'ul#links' do
      expect(page).not_to have_content('Makers Academy')
      expect(page).not_to have_content('Code.org')
      expect(page).to have_content('This is Zombocom')
      expect(page).to have_content('Bubble Bobble')
    end
  end
end

feature 'Viewing links' do
  scenario 'I can see existing links on the links page' do
    Link.create(url: 'http://www.makersacademy.com', title: 'Makers Academy')

    visit '/links'
    expect(page.status_code).to eq 200

    within 'ul#links' do
      expect(page).to have_content "Makers Academy"
    end
  end
end

feature 'Add url links' do
  scenario 'I can add links to bookmark manager' do
    visit '/links/new'

    fill_in :title, with: 'Google'
    fill_in :url, with: 'http://www.google.com'
    click_button "Submit"

    expect(current_path).to eq '/links'

    expect(page).to have_content "Google"
  end
end

feature 'Adding Tags' do
  scenario 'I can add 1 tag to a link' do
    visit '/links/new'
    fill_in :title, with: 'Google'
    fill_in :url, with: 'http://www.google.com'
    fill_in :tags, with: 'drama'
    click_button 'Submit'
    link = Link.first
    expect(link.tags.map(&:name)).to include('drama')
  end
end

feature 'Adding Multiple Tags' do
  scenario 'I can add multiple tags to a link' do
    visit '/links/new'
    fill_in :title, with: 'Google'
    fill_in :url, with: 'http://www.google.com'
    fill_in :tags, with: 'drama adult'
    click_button 'Submit'
    link = Link.first
    expect(link.tags.map(&:name)).to include('drama')
    expect(link.tags.map(&:name)).to include('adult')
  end
end

feature 'User sign up' do
  scenario 'I can sign up as a new user' do

    expect { sign_up("alice@example.com", "oranges!", "oranges!") }.to change(User, :count).by(1)
    expect(page).to have_content('Welcome, alice@example.com')
    expect(User.first.email).to eq('alice@example.com')
  end

  scenario 'Requires a matching confirmation password' do
    expect { sign_up("alice@example.com", "123", "321") }.not_to change(User, :count)
    expect(current_path).to eq '/users'
    expect(page).to have_content "Password does not match the confirmation"
  end

  scenario 'Requires a non-empty email address' do
    expect { sign_up("", "123","123") }.not_to change(User, :count)
  end

  scenario "user can't sign up with invalid format email" do
    expect { sign_up("pep@gmail", "123", "123") }.not_to change(User, :count)
  end

  scenario "user can't sign up if email already registered" do
    sign_up("pepe@uno.com","123","123")
    expect { sign_up("pepe@uno.com", "456", "456") }.not_to change(User, :count)
    expect(current_path).to eq '/users'
    expect(page).to have_content "Email is already taken"
  end
end

feature 'User sign in and out' do

  let(:user) do
    User.create(email: 'user@example.com',
                password: 'secret1234',
                password_confirmation: 'secret1234')
  end

  scenario 'sign in with correct credentials' do
    sign_in(email: user.email, password: user.password)
    expect(page).to have_content "Welcome, #{user.email}"
  end
end

feature 'User signs out' do

  before(:each) do
    User.create(email: 'test@test.com',
                password: 'test',
                password_confirmation: 'test')
  end

  scenario 'while being signed in' do
    sign_in(email: 'test@test.com', password: 'test')
    click_button 'Sign out'
    expect(page).to have_content('goodbye!')
    expect(page).not_to have_content('Welcome, test@test.com')
  end

end

feature 'Resetting password' do
  before do
    sign_up("alice@example.com","pwd", "pwd")
    Capybara.reset!
  end
  let(:user) { User.first }

  scenario 'link to reset password' do
    visit '/sessions/new'
    click_link 'I forgot my password'
    expect(page).to have_content('Please enter your email address')
  end

  scenario 'When I enter my email I am told to check my inbox' do
    recover_password
    expect(page).to have_content "Thanks, Please check your inbox for the link."
  end

  scenario 'assigned a reset token to the user when they recover' do
    sign_up("alice@example.com","pwd", "pwd")
    expect{recover_password}.to change{User.first.password_token}
  end

  scenario 'it doesn\'t allow you to use the token after an hour' do
    recover_password
    Timecop.travel(60 * 60 * 60) do
      visit("/users/reset_password?token=#{user.password_token}")
      expect(page).to have_content "Your token is invalid"
    end
  end

  scenario 'it asks for your new password when your token is valid' do
    recover_password
    visit("/users/reset_password?token=#{user.password_token}")
    expect(page).to have_content("Please enter your new password")
  end

  scenario 'it lets you enter a new password with a valid token' do
    recover_password
    visit("/users/reset_password?token=#{user.password_token}")
    fill_in :password, with: "newpassword"
    fill_in :password_confirmation, with: "newpassword"
    click_button "Submit"
    expect(page).to have_content("Please sign in")
  end

  scenario 'it lets you sign in after password reset' do
   recover_password
   visit("/users/reset_password?token=#{user.password_token}")
   fill_in :password, with: "newpassword"
   fill_in :password_confirmation, with: "newpassword"
   click_button "Submit"
   sign_in(email: "alice@example.com", password: "newpassword")
   expect(page).to have_content "Welcome, alice@example.com"
 end

 scenario 'it lets you know if your passwords don\'t match' do
   recover_password
   visit("/users/reset_password?token=#{user.password_token}")
   fill_in :password, with: "newpassword"
   fill_in :password_confirmation, with: "wrongpassword"
   click_button "Submit"
   expect(page).to have_content("Password does not match the confirmation")
 end

end