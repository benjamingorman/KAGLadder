import React, { Component } from 'react';
import './RegionSelectButton.css';

class RegionSelectButton extends Component {
    render() {
        let flagUrl;
        switch(this.props.region) {
            case "Europe":
                flagUrl = "flags/EU.gif";
                break;
            case "United States":
                flagUrl = "flags/US.gif";
                break;
            case "Australia":
                flagUrl = "flags/AUS.gif";
                break;
            default:
                flagUrl = "flags/EU.gif";
        }

        return (
            <div className={"RegionSelectButton " + (this.props.selected ? "selected" : "")} onClick={this.props.onClick}>
                <img src={flagUrl} alt={this.props.region} />
                <span>{this.props.region}</span>
            </div>
        );
    }
}
export default RegionSelectButton;
