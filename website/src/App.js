import React, { Component } from 'react';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import 'react-tabs/style/react-tabs.css';
import logo from './logo.svg';
import './App.css';
import Leaderboard from './components/Leaderboard.js';
import MatchHistory from './components/MatchHistory.js';
import RegionSelect from './components/RegionSelect.js';
import ClassSelect from './components/ClassSelect.js';
import PlayerProfile from './components/PlayerProfile.js';
//import sampleEntries from './sampleEntries';

class App extends Component {
    constructor(props) {
        super(props);
        this.state = {selectedRegion: "EU", selectedClass: "knight"};
    }

    render() {
        return (
            <div className="App">
                <header className="App-header">
                    <img className="App-logo" alt="App logo" src={logo}/>
                </header>
                <Tabs defaultIndex={0}>
                    <TabList>
                        <Tab>Leaderboard</Tab>
                        <Tab>Match History</Tab>
                        <Tab>Player Profiles</Tab>
                    </TabList>

                    <TabPanel>
                        <RegionSelect onChange={(val) => this.changeSelectedRegion(val)} />
                        <div className="_classSelect">
                            <ClassSelect onChange={(val) => this.changeSelectedClass(val)} />
                        </div>
                        <Leaderboard region={this.state.selectedRegion} kagClass={this.state.selectedClass} />
                    </TabPanel>

                    <TabPanel>
                        <MatchHistory />
                    </TabPanel>

                    <TabPanel>
                        <PlayerProfile username="madhawk99" />
                    </TabPanel>
                </Tabs>
            </div>
        );
    }

    changeSelectedRegion(region) {
        console.log("changeSelectedRegion", region);
        this.setState({selectedRegion: region});
    }

    changeSelectedClass(kagClass) {
        console.log("changeSelectedClass", kagClass);
        this.setState({selectedClass: kagClass});
    }
}

export default App;
