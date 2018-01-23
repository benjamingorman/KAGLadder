import React, { Component } from 'react';
import './ClassSelect.css';

class ClassSelect extends Component {
    render() {
        return (
            <div className="ClassSelect row">
                {this.props.children}
            </div>
        );
    }
}
export default ClassSelect;
