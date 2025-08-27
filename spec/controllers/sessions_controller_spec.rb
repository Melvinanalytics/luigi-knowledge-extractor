require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:luigi_expert) { create(:luigi_expert) }
  
  before do
    # Mock the current luigi expert (assuming this is how authentication works)
    allow(controller).to receive(:current_luigi).and_return(luigi_expert)
    controller.instance_variable_set(:@luigi, luigi_expert)
  end

  describe 'GET #index' do
    let!(:session1) { create(:luigi_session, luigi_expert: luigi_expert) }
    let!(:session2) { create(:luigi_session, luigi_expert: luigi_expert) }

    before do
      create(:luigi_message, luigi_session: session1, entities_extracted: 5)
      create(:luigi_message, luigi_session: session2, entities_extracted: 3)
    end

    it 'returns successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns sessions ordered by most recent' do
      get :index
      expect(assigns(:sessions)).to include(session1, session2)
    end

    it 'calculates total stats correctly' do
      get :index
      stats = assigns(:total_stats)
      
      expect(stats[:total_sessions]).to eq(2)
      expect(stats[:total_knowledge]).to eq(8) # 5 + 3 entities
    end
  end

  describe 'GET #show' do
    let(:luigi_session) { create(:luigi_session, luigi_expert: luigi_expert) }
    let!(:message1) { create(:luigi_message, luigi_session: luigi_session) }
    let!(:message2) { create(:luigi_message, luigi_session: luigi_session) }

    it 'returns successful response' do
      get :show, params: { id: luigi_session.id }
      expect(response).to be_successful
    end

    it 'assigns the correct session' do
      get :show, params: { id: luigi_session.id }
      expect(assigns(:session)).to eq(luigi_session)
    end

    it 'assigns messages in chronological order' do
      get :show, params: { id: luigi_session.id }
      messages = assigns(:messages)
      expect(messages).to include(message1, message2)
    end

    it 'sets current session id in session' do
      get :show, params: { id: luigi_session.id }
      expect(session[:current_session_id]).to eq(luigi_session.id)
    end

    context 'when session does not exist' do
      it 'redirects to root path with alert' do
        get :show, params: { id: 'non-existent' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Session nicht gefunden.')
      end
    end
  end

  describe 'POST #create' do
    it 'creates a new session' do
      expect {
        post :create
      }.to change(LuigiSession, :count).by(1)
    end

    it 'assigns session to the current luigi expert' do
      post :create
      session = assigns(:session)
      expect(session.luigi_expert).to eq(luigi_expert)
    end

    it 'sets session as active by default' do
      post :create
      session = assigns(:session)
      expect(session.status).to eq('active')
    end

    it 'enqueues knowledge graph job' do
      expect(KnowledgeGraph::CreateSessionJob).to receive(:perform_later)
      post :create
    end

    it 'creates welcome message' do
      expect {
        post :create
      }.to change(LuigiMessage, :count).by(1)
      
      welcome_message = LuigiMessage.last
      expect(welcome_message.message_type).to eq('system')
      expect(welcome_message.content).to include('Hallo Luigi!')
    end

    it 'sets current session id in session' do
      post :create
      session_obj = assigns(:session)
      expect(session[:current_session_id]).to eq(session_obj.id)
    end

    context 'successful creation' do
      it 'redirects to the new session' do
        post :create
        expect(response).to redirect_to(assigns(:session))
        expect(flash[:notice]).to eq('Neue Wissenssession gestartet!')
      end
    end

    context 'when creation fails' do
      before do
        # Force validation failure
        allow_any_instance_of(LuigiSession).to receive(:save).and_return(false)
      end

      it 'redirects to root with alert' do
        post :create
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Session konnte nicht erstellt werden.')
      end
    end
  end

  describe 'GET #export' do
    let(:luigi_session) { create(:luigi_session, luigi_expert: luigi_expert) }
    let(:export_service) { instance_double(KnowledgeExportService) }
    let(:export_data) { { entities: [], relationships: [] } }

    before do
      allow(KnowledgeExportService).to receive(:new).with(luigi_session).and_return(export_service)
    end

    context 'successful export' do
      before do
        allow(export_service).to receive(:call).and_return(
          double(success?: true, value!: export_data)
        )
      end

      it 'returns successful response' do
        get :export, params: { id: luigi_session.id }, format: :json
        expect(response).to be_successful
      end

      it 'returns JSON data' do
        get :export, params: { id: luigi_session.id }, format: :json
        expect(response.content_type).to include('application/json')
      end
    end

    context 'failed export' do
      before do
        allow(export_service).to receive(:call).and_return(
          double(success?: false, failure: 'Export failed')
        )
      end

      it 'returns unprocessable entity status' do
        get :export, params: { id: luigi_session.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end