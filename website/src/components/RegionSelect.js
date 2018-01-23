import React, { Component } from 'react';
import './RegionSelect.css';

class RegionSelect extends Component {
    render() {
        return (
            <div className="RegionSelect row">
                {this.props.children}
            </div>
        );
    }
}
export default RegionSelect;
