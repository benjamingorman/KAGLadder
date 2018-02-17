import React, { Component } from 'react';
import {RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar} from 'recharts';
import './PlayerStatsBox.css';
import ComingSoonBanner from './ComingSoonBanner';

class PlayerStatsBox extends Component {
    render() {
        let data = [
            { attack: "Jab", A: 1.0 }, 
            { attack: "Slash", A: 0.6 }, 
            { attack: "Power Slash", A: 0.4 }, 
            { attack: "Shield Bash", A: 0.44 }, 
            { attack: "Bombs", A: 0.32 }, 
        ];

        return (
            <div className="PlayerStatsBox box">
                <div className="_box_label">Stats</div>
                <ComingSoonBanner />
                <div className="grid-centered">
                    <RadarChart cx={150} cy={125} outerRadius={75} width={300} height={250} data={data}>
                        <PolarGrid />
                        <PolarAngleAxis dataKey="attack" />
                        <Radar name="Eluded" dataKey="A" stroke="#8884d8" fill="#8884d8" fillOpacity={0.6}/>
                    </RadarChart>               
                </div>
            </div>
        );
    }
}
export default PlayerStatsBox;
