import React, { Component } from 'react';
import './LeaderboardPage.css';
import RegionSelect from '../components/RegionSelect.js';
import ClassSelect from '../components/ClassSelect.js';
import Leaderboard from '../components/Leaderboard.js';
import Page from './Page';

class LeaderboardPage extends Component {
    constructor(props) {
        super(props);
        this.state = {selectedRegion: "EU", selectedClass: "knight"};
    }

    render() {
        return (
            <div className="LeaderboardPage">
                <Page title="Leaderboard">
                    <RegionSelect onChange={(val) => this.changeSelectedRegion(val)} />
                    <ClassSelect onChange={(val) => this.changeSelectedClass(val)} />
                    <Leaderboard region={this.state.selectedRegion} kagClass={this.state.selectedClass} />
                </Page>
            </div>
        );
    }

    changeSelectedRegion(region) {
        //console.log("changeSelectedRegion", region);
        this.setState({selectedRegion: region});
    }

    changeSelectedClass(kagClass) {
        //console.log("changeSelectedClass", kagClass);
        this.setState({selectedClass: kagClass});
    }
}
export default LeaderboardPage;
