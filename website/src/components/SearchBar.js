import React, { Component } from 'react';
import './SearchBar.css';

class SearchBar extends Component {
    /*
    constructor(props) {
        super(props);
        this.state = {typed: ''};
    }
    */

    render() {
        let {onChange, ...rest} = this.props;
        return (
            <input className="SearchBar" onKeyUp={(v) => this.onKeyUp(v)} {...rest} />
        );
    }

    onKeyUp(e) {
        if (e.keyCode === 13) { // enter key
            let val = e.target.value;
            //this.state.typed = val;
            this.props.onChange(val);
        }
    }
}
export default SearchBar;
