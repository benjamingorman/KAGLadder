import React, { Component } from 'react';
import './CharacterPortrait.css';
import * as utils from '../utils';

class CharacterPortrait extends Component {
    render() {
        let headFile = "svgheads/head0-1.svg";
        if (this.props.head) {
            headFile = "svgheads/head0-" + this.props.head + ".svg";
        }

        let bodyFile = "svgbodies/KnightMale.svg";
        if (this.props.kagClass != undefined && this.props.gender != undefined) {
            bodyFile = "svgbodies/" + utils.capitalizeString(this.props.kagClass) + utils.genderToString(this.props.gender) + ".svg";
        }

        return (
            <div className="CharacterPortrait">
                <div className="_inner">
                    <img className="_head" src={headFile} alt="Character head" />
                    <img className="_body" src={bodyFile} alt="Character body" />
                </div>
            </div>
        );
    }
}
export default CharacterPortrait;
