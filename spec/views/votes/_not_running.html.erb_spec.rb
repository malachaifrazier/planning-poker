require 'rails_helper'
require 'support/matchers/histogram_matchers'


describe "votes/_not_running" do

  before :each do
    @team = Team.create(name: "Daltons")
    @joe = @team.contributors.create(name: "Joe")
  end

  it "displays a Start Vote button to the animator" do
    @team.if_needed_pick_animator(@joe)

    render_partial

    expect(rendered).to have_button("Start Vote")
  end

  it "does not display a Start Vote button to other contributors" do
    render_partial

    expect(rendered).not_to have_button("Start Vote")
  end

  it "does not display any average estimate" do
    render_partial

    expect(rendered).not_to include("average estimate")
  end

  it "does not display vote histograms" do
    render_partial

    expect(rendered).not_to have_xpath("//progress")
  end

  describe "When a vote has ended" do

    before :each do
      @ending = DateTime.parse("2000-05-01T08:02:34Z")
      @vote = @team.start_vote(@ending)
      @awrel = @team.contributors.create(name: "Awrel")
      @howard = @team.contributors.create(name: "Howard")
    end

    it "displays the average estimate" do
      @joe.estimate(@vote, points: 5)

      render_partial

      expect(rendered).to include("average estimate : 5")
    end

    it "displays the average estimate" do
      @joe.estimate(@vote, points: 5)
      @awrel.estimate(@vote, points: 3)
      @howard.estimate(@vote, points: 3)

      render_partial

      expect(rendered).to include("average estimate : 3.67")
    end

    it "displays a question mark if no estimations were given" do
      render_partial

      expect(rendered).to include("average estimate : ?")
    end

    describe "estimations histograms" do

      before :each do
        @joe.estimate(@vote, points: 5)
      end

      it "for 1 vote" do
        render_partial

        expect(rendered).to have_histogram(5, value: 1)
      end

      it "for 2 votes" do
        @awrel.estimate(@vote, points: 3)

        render_partial

        expect(rendered).to have_histogram(5, value: 1)
        expect(rendered).to have_histogram(3,  value: 1)
      end

      it "for 2 identical votes" do
        @awrel.estimate(@vote, points: 5)

        render_partial

        expect(rendered).to have_histogram(5, value: 2)
      end

      it "scales to the max number of identical votes" do
        @awrel.estimate(@vote, points: 5)

        render_partial

        PhilousPlanningPoker::FIBOS.each do |points|
          expect(rendered).to have_histogram(points, max: 2)
        end
      end
    end
  end

  def render_partial
    assign(:contributor, @joe)
    render partial: "votes/not_running", locals: {vote: @team.current_vote}
  end

end
