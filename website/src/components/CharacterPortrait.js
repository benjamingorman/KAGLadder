import React, { Component } from 'react';
import './CharacterPortrait.css';
import * as utils from '../utils';

class CharacterPortrait extends Component {
    render() {
        let genderString = utils.genderToString(this.props.gender);
        let bodyFile = "bodies/" + utils.capitalizeString(this.props.kagClass) + genderString + ".png";

        let headsDir = "male";
        if (this.props.head <= 28) {
            headsDir = "custom";
        }
        else if (this.props.gender === 1) {
            headsDir = "female";
        }

        let headFile = `heads/${headsDir}/${this.props.head}.png`;

        return (
            <div className="CharacterPortrait">
                <div className="_inner">
                    <img className="_body" src={bodyFile} alt="Character body" />
                    <img className={"_head _" + this.props.kagClass} src={headFile} alt="Character head" />
                </div>
            </div>
            );
    }
}
export default CharacterPortrait;
