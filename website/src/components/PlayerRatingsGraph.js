import React, { Component } from 'react';
import './PlayerRatingsGraph.css';
import {AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip} from 'recharts';
import RegionSelect from './RegionSelect';
import ClassSelect from './ClassSelect';
import * as utils from '../utils';

class PlayerRatingsGraph extends Component {
    constructor(props) {
        super(props);
        this.state = {selectedRegion: "EU", selectedClass: "knight"};
    }

    render() {
        let matches = this.props.matches;
        let selectedRegion = this.state.selectedRegion;
        let selectedClass = this.state.selectedClass;
        let data = [];

        let rating = 1000;
        let minRating = Number.MAX_VALUE;
        let maxRating = Number.MIN_VALUE;
        data.push({[selectedClass]: rating});

        // Matches are already sorted in descending order of time so iterate from the end
        // To go in time order
        for (let i=matches.length-1; i >= 0; --i) {
            let match = matches[i];
            // console.log("match", match) ;

            if (!(match.region === selectedRegion && match.kag_class === selectedClass))
                continue;

            let ratingChange = 0;
            let otherPlayer;

            if (match.player1 === this.props.username) {
                ratingChange = match.player1_rating_change;
                otherPlayer = match.player2;
            }
            else if (match.player2 === this.props.username) {
                ratingChange = match.player2_rating_change;
                otherPlayer = match.player1;
            }
            else
                console.warn("PlayerRatingsGraph", "player name not found in match", this.props.username);

            rating += ratingChange;
            if (rating < minRating)
                minRating = rating;
            if (rating > maxRating)
                maxRating = rating;

            let [dateString, timeString] = utils.unixTimeToDateAndTime(match.match_time);

            data.push({[selectedClass]: rating});
        }

        /*
        for (let j=0; j < 50; ++j) {
            rating += Math.floor((Math.random()-0.5) * 100);
            data.push({[selectedClass]: rating});
        }
        */

        let x = 40;
        let verticalPoints = [1*x,2*x,3*x,4*x,5*x];

        return (
            <div className="PlayerRatingsGraph box">
                <div className="_box_label">Rating Graph</div>
                <RegionSelect onChange={(val) => this.changeSelectedRegion(val)} />
                <ClassSelect onChange={(val) => this.changeSelectedClass(val)} />

                <div className="_graph">
                    <AreaChart width={320} height={150} data={data}
                        margin={{top: 20, right: 15, left: 0, bottom: 5}}>
                        <defs>
                            <linearGradient id="colorGradient" x1="0" y1="0" x2="0" y2="1">

                                <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                                <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                            </linearGradient>
                        </defs>
                        <XAxis dataKey="name"/>
                        <YAxis domain={[minRating, maxRating]}/>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} horizontal={false} verticalPoints={verticalPoints}/>
                        <Tooltip/>
                        {/*<Legend />*/}
                        <Area type="monotone" dataKey={selectedClass} stroke="#8884d8" activeDot={{r: 8}}
                            fillOpacity={1} fill="url(#colorGradient)"/>
                    </AreaChart>
                </div>
            </div>
            );
    }

    changeSelectedRegion(val) {
        this.setState({selectedRegion: val});
    }

    changeSelectedClass(val) {
        this.setState({selectedClass: val});
    }
}

export default PlayerRatingsGraph;
