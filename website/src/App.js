import React, { Component } from 'react';
// import logo from './logo.svg';
import './App.css';
import Leaderboard from './components/Leaderboard.js';
import RegionSelect from './components/RegionSelect.js';
import RegionSelectButton from './components/RegionSelectButton.js';
import ClassSelect from './components/ClassSelect.js';
import ClassSelectButton from './components/ClassSelectButton.js';
import sampleEntries from './sampleEntries';

class App extends Component {
    constructor(props) {
        super(props);
        this.state = {selectedRegion: "Europe", selectedClass: "knight"};
    }

    render() {
        let entries = sampleEntries;

        let regions = ["Europe", "United States", "Australia"];
        let regionButtons = [];
        for (let i=0; i < regions.length; ++i) {
            regionButtons.push(<RegionSelectButton key={i} region={regions[i]} selected={this.state.selectedRegion == regions[i]}
                                                   onClick={() => this.changeSelectedRegion(regions[i])}
                               />);
        }

        let kagClasses = ["knight", "archer", "builder"];
        let classButtons = [];
        for (let i=0; i < kagClasses.length; ++i) {
            classButtons.push(<ClassSelectButton key={i} kagClass={kagClasses[i]} selected={this.state.selectedClass == kagClasses[i]}
                                                  onClick={() => this.changeSelectedClass(kagClasses[i])}
                              />);
        }

        return (
            <div className="App">
                <header className="App-header">
                    <h1 className="App-title">KAG 1v1 Ladder</h1>
                </header>
                <div className="App-leaderboard-container">
                    <RegionSelect>
                        {regionButtons}
                    </RegionSelect>
                    <ClassSelect>
                        {classButtons}
                    </ClassSelect>
                    <Leaderboard region="Europe" entries={entries} />
                </div>
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
