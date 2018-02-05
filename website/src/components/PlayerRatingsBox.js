import React, { Component } from 'react';
import './PlayerRatingsBox.css';
//import RadioGroup from './RadioGroup';
//import RadioButton from './RadioButton';
import RegionSelect from './RegionSelect';
import ClassIcon from './ClassIcon';
import WinRatio from './WinRatio';
import * as utils from '../utils';

class PlayerRatingsBox extends Component {
    constructor(props) {
        super(props);
        this.state = {selectedRegion: "EU"};
    }

    render() {
        let rows = [];
        let winRatios = [];
        let k=0;
        let ratData = this.props.ratings[this.state.selectedRegion];

        for (let kag_class of utils.getValidKagClasses()) {
            if (!ratData[kag_class]) 
                continue;

            let rat = ratData[kag_class]["rating"];
            let title = utils.getTitleFromRating(rat);
            rows.push(<tr key={k++}>
                        <td><ClassIcon kagClass={kag_class} /></td>
                        <td>{title} {kag_class}</td>
                        <td>{rat}</td>
                      </tr>);
            
            winRatios.push(
                <div key={k++}>
                    <ClassIcon kagClass={kag_class} />
                    <WinRatio wins={ratData[kag_class]["wins"]} losses={ratData[kag_class]["losses"]} />
                </div>
                );
        }

        return (
            <div className="PlayerRatingsBox box">
                <div className="_box_label">
                    Ratings
                </div>
                <RegionSelect onChange={(val) => this.changeSelectedRegion(val)} />
                <table>
                    <tbody>
                        {rows}
                    </tbody>
                </table>

                <div className="_winRatios">
                    {winRatios}
                </div>
            </div>
        );
    }

    changeSelectedRegion(region) {
        //console.log("changeSelectedRegion", region);
        this.setState({selectedRegion: region});
    }
}
export default PlayerRatingsBox;
